import subprocess
import sys
import tempfile
import unittest
from io import StringIO
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from bloodstream_docker.cli import (
    _parser,
    build_container_command,
    check_apptainer,
    check_docker,
    check_memory,
    ensure_image_ready,
    ensure_sif_ready,
    main,
    maybe_pull_image,
)


def abs_path(path):
    return str(Path(path).expanduser().absolute())


class DockerCommandTests(unittest.TestCase):
    def test_no_arguments_parse_without_path_traceback(self):
        opts = _parser().parse_args([])

        self.assertIsNone(opts.bids_dir)
        self.assertIsNone(opts.output_dir)

    def test_builds_bids_app_like_pipeline_command(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bids = root / "bids"
            derivatives = root / "derivatives"
            config = root / "my_config.json"
            bids.mkdir()
            config.write_text("{}")

            opts = _parser().parse_args(
                [
                    str(bids),
                    str(derivatives),
                    "participant",
                    "--config",
                    str(config),
                    "--analysis-foldername",
                    "Model_AIF",
                    "--automatic",
                    "--no-tty",
                    "--dry-run",
                ]
            )

            command = build_container_command(opts)

            self.assertEqual(command[:3], ["docker", "run", "--rm"])
            self.assertIn("--platform", command)
            self.assertIn("linux/amd64", command)
            self.assertNotIn("-it", command)
            self.assertIn("mathesong/bloodstream:latest", command)
            self.assertIn(f"{abs_path(bids)}:/data/bids_dir:ro", command)
            self.assertIn(f"{abs_path(derivatives)}:/data/derivatives_dir:rw", command)
            self.assertIn(f"{abs_path(config)}:/config.json:ro", command)
            mode_index = command.index("--mode")
            self.assertEqual(command[mode_index + 1], "non-interactive")
            folder_index = command.index("--analysis_foldername")
            self.assertEqual(command[folder_index + 1], "Model_AIF")
            config_index = command.index("--config")
            self.assertEqual(command[config_index + 1], "/config.json")
            self.assertTrue(derivatives.exists())

    def test_interactive_mode_is_default(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bids = root / "bids"
            derivatives = root / "derivatives"
            bids.mkdir()

            opts = _parser().parse_args(
                [str(bids), str(derivatives), "participant", "--no-tty", "--dry-run"]
            )

            command = build_container_command(opts)

            mode_index = command.index("--mode")
            self.assertEqual(command[mode_index + 1], "interactive")
            self.assertIn("BLOODSTREAM_SHINY_PORT=3838", command)
            self.assertIn("SHINY_SERVER_VERSION=", command)
            self.assertIn("3838:3838", command)

    def test_interactive_mode_needs_no_paths_for_config_creation(self):
        opts = _parser().parse_args(["--interactive", "--no-tty", "--dry-run"])

        command = build_container_command(opts)

        self.assertNotIn("-v", command)
        self.assertIn("3838:3838", command)
        mode_index = command.index("--mode")
        self.assertEqual(command[mode_index + 1], "interactive")

    def test_non_interactive_mode_requires_paths(self):
        opts = _parser().parse_args(["--automatic", "--dry-run"])

        with self.assertRaises(SystemExit) as caught:
            build_container_command(opts)

        self.assertIn("bids_dir", str(caught.exception))
        self.assertIn("output_dir", str(caught.exception))

    def test_bids_dir_without_output_dir_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            bids = Path(tmpdir) / "bids"
            bids.mkdir()

            opts = _parser().parse_args([str(bids), "--interactive", "--dry-run"])

            with self.assertRaises(SystemExit) as caught:
                build_container_command(opts)

        self.assertIn("output_dir is required", str(caught.exception))

    def test_output_dir_can_be_final_bloodstream_directory(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bids = root / "bids"
            derivatives = root / "derivatives"
            bloodstream_output = derivatives / "bloodstream"
            bids.mkdir()

            opts = _parser().parse_args(
                [str(bids), str(bloodstream_output), "participant", "--no-tty", "--dry-run"]
            )

            command = build_container_command(opts)

            self.assertIn(f"{abs_path(derivatives)}:/data/derivatives_dir:rw", command)
            self.assertNotIn(f"{abs_path(bloodstream_output)}:/data/derivatives_dir:rw", command)
            self.assertTrue(bloodstream_output.exists())

    def test_missing_config_file_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bids = root / "bids"
            bids.mkdir()

            opts = _parser().parse_args(
                [
                    str(bids),
                    str(root / "derivatives"),
                    "participant",
                    "--config",
                    str(root / "absent.json"),
                    "--dry-run",
                ]
            )

            with self.assertRaises(SystemExit) as caught:
                build_container_command(opts)

        self.assertIn("existing config file", str(caught.exception))

    def test_interactive_mode_maps_port_and_env(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bids = root / "bids"
            bids.mkdir()

            opts = _parser().parse_args(
                [
                    str(bids),
                    str(root / "derivatives"),
                    "participant",
                    "--mode",
                    "interactive",
                    "--port",
                    "3840",
                    "--no-tty",
                    "--dry-run",
                ]
            )

            command = build_container_command(opts)

            self.assertIn("-p", command)
            self.assertIn("3840:3840", command)
            self.assertIn("-e", command)
            self.assertIn("BLOODSTREAM_SHINY_PORT=3840", command)

    def test_patch_mounts_local_bloodstream(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bids = root / "bids"
            patch_dir = root / "bloodstream"
            bids.mkdir()
            patch_dir.mkdir()

            opts = _parser().parse_args(
                [
                    str(bids),
                    str(root / "derivatives"),
                    "participant",
                    "--patch",
                    str(patch_dir),
                    "--no-tty",
                    "--dry-run",
                ]
            )

            command = build_container_command(opts)

            self.assertIn(f"{abs_path(patch_dir)}:/patch/bloodstream:ro", command)

    def test_patch_works_with_shell(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            patch_dir = Path(tmpdir) / "bloodstream"
            patch_dir.mkdir()

            opts = _parser().parse_args(
                ["--shell", "--patch", str(patch_dir), "--no-tty", "--dry-run"]
            )

            command = build_container_command(opts)

            self.assertIn(f"{abs_path(patch_dir)}:/patch/bloodstream:ro", command)
            self.assertIn("--entrypoint", command)


class ApptainerCommandTests(unittest.TestCase):
    def test_builds_apptainer_run_command(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bids = root / "bids"
            derivatives = root / "derivatives"
            config = root / "config.json"
            bids.mkdir()
            config.write_text("{}")

            opts = _parser().parse_args(
                [
                    str(bids),
                    str(derivatives),
                    "participant",
                    "--apptainer",
                    "--config",
                    str(config),
                    "--automatic",
                    "--dry-run",
                ]
            )

            command = build_container_command(opts)

            self.assertEqual(command[:3], ["apptainer", "run", "--cleanenv"])
            self.assertIn("bloodstream_latest.sif", command)
            self.assertIn(f"{abs_path(bids)}:/data/bids_dir:ro", command)
            self.assertIn(f"{abs_path(derivatives)}:/data/derivatives_dir:rw", command)
            self.assertIn(f"{abs_path(config)}:/config.json:ro", command)
            self.assertIn("/tmp:/tmp", command)
            self.assertNotIn("-v", command)
            self.assertNotIn("-p", command)
            self.assertNotIn("--platform", command)
            self.assertIn("-B", command)

    def test_apptainer_interactive_passes_port_as_env(self):
        opts = _parser().parse_args(["--apptainer", "--interactive", "--port", "8080", "--dry-run"])

        command = build_container_command(opts)

        self.assertIn("--env", command)
        self.assertIn("BLOODSTREAM_SHINY_PORT=8080", command)
        self.assertNotIn("8080:8080", command)

    def test_singularity_executable_is_used(self):
        opts = _parser().parse_args(["--container", "singularity", "--interactive", "--dry-run"])

        command = build_container_command(opts)

        self.assertEqual(command[0], "singularity")

    def test_apptainer_shell_uses_shell_subcommand(self):
        opts = _parser().parse_args(["--apptainer", "--shell", "--dry-run"])

        command = build_container_command(opts)

        self.assertEqual(command[:3], ["apptainer", "shell", "--cleanenv"])
        self.assertNotIn("--mode", command)

    def test_no_cleanenv_drops_the_flag(self):
        opts = _parser().parse_args(["--apptainer", "--interactive", "--no-cleanenv", "--dry-run"])

        command = build_container_command(opts)

        self.assertNotIn("--cleanenv", command)

    def test_docker_only_options_are_noted_not_applied(self):
        opts = _parser().parse_args(
            ["--apptainer", "--interactive", "--user", "1000:1000", "--dry-run"]
        )

        with patch("sys.stderr", new_callable=StringIO) as stderr:
            command = build_container_command(opts)

        self.assertNotIn("--user", command)
        self.assertIn("--user", stderr.getvalue())

    def test_missing_sif_reports_build_command(self):
        with self.assertRaises(SystemExit) as caught:
            ensure_sif_ready("absent_bloodstream.sif")

        self.assertIn("apptainer build absent_bloodstream.sif", str(caught.exception))

    def test_remote_uri_is_left_to_apptainer(self):
        self.assertIsNone(ensure_sif_ready("docker://mathesong/bloodstream:latest"))

    def test_check_apptainer_reports_missing_executable(self):
        with patch("bloodstream_docker.cli.subprocess.run", side_effect=OSError("No such file")):
            with self.assertRaises(SystemExit) as caught:
                check_apptainer("apptainer")

        self.assertIn("module load apptainer", str(caught.exception))

    def test_main_checks_apptainer_and_image(self):
        with patch("bloodstream_docker.cli.check_apptainer") as apptainer_check:
            with patch("bloodstream_docker.cli.ensure_sif_ready") as sif_check:
                with patch("bloodstream_docker.cli.check_docker") as docker_check:
                    with patch("bloodstream_docker.cli.subprocess.call", return_value=0) as call:
                        with patch("sys.stdout", new_callable=StringIO):
                            self.assertEqual(main(["--apptainer", "--interactive"]), 0)

        apptainer_check.assert_called_once_with("apptainer")
        sif_check.assert_called_once_with("bloodstream_latest.sif")
        docker_check.assert_not_called()
        call.assert_called_once()


class RuntimeCheckTests(unittest.TestCase):
    def test_check_docker_surfaces_daemon_error(self):
        error = subprocess.CalledProcessError(
            1,
            ["docker", "info"],
            stderr="Cannot connect to the Docker daemon at unix:///tmp/docker.sock. Is the docker daemon running?\n",
        )

        with patch("bloodstream_docker.cli.subprocess.run", side_effect=error):
            with patch("sys.stderr", new_callable=StringIO) as stderr:
                with self.assertRaises(SystemExit) as caught:
                    check_docker()

        self.assertIn("Cannot connect to the Docker daemon", stderr.getvalue())
        self.assertIn("Could not detect memory capacity", stderr.getvalue())
        self.assertEqual(str(caught.exception), "Do you have permission to run docker?")

    def test_main_checks_docker_and_image_before_required_paths(self):
        with patch("bloodstream_docker.cli.check_docker") as docker_check:
            with patch("bloodstream_docker.cli.ensure_image_ready") as ensure_image:
                with self.assertRaises(SystemExit) as caught:
                    main(["--automatic"])

        docker_check.assert_called_once()
        ensure_image.assert_called_once_with("mathesong/bloodstream:latest", platform="linux/amd64")
        self.assertIn("bids_dir", str(caught.exception))

    def test_main_stops_on_docker_failure_before_image_check(self):
        with patch("bloodstream_docker.cli.check_docker", side_effect=SystemExit("docker failed")):
            with patch("bloodstream_docker.cli.ensure_image_ready") as ensure_image:
                with self.assertRaises(SystemExit) as caught:
                    main(["--automatic"])

        ensure_image.assert_not_called()
        self.assertEqual(str(caught.exception), "docker failed")

    def test_main_dry_run_skips_docker_and_image_checks(self):
        with patch("bloodstream_docker.cli.check_docker") as docker_check:
            with patch("bloodstream_docker.cli.ensure_image_ready") as ensure_image:
                with self.assertRaises(SystemExit) as caught:
                    main(["--automatic", "--dry-run"])

        docker_check.assert_not_called()
        ensure_image.assert_not_called()
        self.assertIn("bids_dir", str(caught.exception))

    def test_main_skip_image_check_still_checks_docker(self):
        with patch("bloodstream_docker.cli.check_docker") as docker_check:
            with patch("bloodstream_docker.cli.ensure_image_ready") as ensure_image:
                with self.assertRaises(SystemExit) as caught:
                    main(["--automatic", "--skip-image-check"])

        docker_check.assert_called_once()
        ensure_image.assert_not_called()
        self.assertIn("bids_dir", str(caught.exception))

    def test_missing_image_prompts_and_defers_pull_to_memory_probe(self):
        with patch("bloodstream_docker.cli.image_exists", return_value=False):
            with patch("builtins.input", return_value="y"):
                with patch("sys.stdout", new_callable=StringIO) as stdout:
                    maybe_pull_image("mathesong/bloodstream:latest")

        self.assertIn("Downloading. This may take a while...", stdout.getvalue())

    def test_check_memory_reads_container_memory(self):
        result = subprocess.CompletedProcess(
            [
                "docker",
                "run",
                "--rm",
                "--platform",
                "linux/amd64",
                "--entrypoint=free",
                "mathesong/bloodstream:latest",
                "-m",
            ],
            0,
            stdout=b"              total        used        free\nMem:           15999        1000       14999\n",
        )

        with patch("bloodstream_docker.cli.subprocess.run", return_value=result) as run:
            self.assertEqual(check_memory("mathesong/bloodstream:latest"), 15999)
        run.assert_called_once_with(
            [
                "docker",
                "run",
                "--rm",
                "--platform",
                "linux/amd64",
                "--entrypoint=free",
                "mathesong/bloodstream:latest",
                "-m",
            ],
            stdout=subprocess.PIPE,
        )

    def test_platform_can_be_disabled_for_native_multiarch_images(self):
        result = subprocess.CompletedProcess(
            ["docker", "run", "--rm", "--entrypoint=free", "custom/bloodstream:arm64", "-m"],
            0,
            stdout=b"Mem:           32000        1000       31000\n",
        )

        with patch("bloodstream_docker.cli.subprocess.run", return_value=result) as run:
            self.assertEqual(check_memory("custom/bloodstream:arm64", platform=None), 32000)

        run.assert_called_once_with(
            ["docker", "run", "--rm", "--entrypoint=free", "custom/bloodstream:arm64", "-m"],
            stdout=subprocess.PIPE,
        )

    def test_failed_memory_probe_exits_without_traceback(self):
        with patch("bloodstream_docker.cli.maybe_pull_image"):
            with patch("bloodstream_docker.cli.check_memory", return_value=-1):
                with patch("sys.stderr", new_callable=StringIO) as stderr:
                    with self.assertRaises(SystemExit) as caught:
                        ensure_image_ready("mathesong/bloodstream:latest")

        self.assertIn("Could not detect memory capacity", stderr.getvalue())
        self.assertEqual(str(caught.exception), "Do you have permission to run docker?")


if __name__ == "__main__":
    unittest.main()
