"""Command line wrapper for running bloodstream in Docker or Apptainer."""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Sequence

from ._version import __version__

DEFAULT_IMAGE = "mathesong/bloodstream:latest"
DEFAULT_SIF = "bloodstream_latest.sif"
DEFAULT_PLATFORM = "linux/amd64"
DEFAULT_PORT = 3838
MODES = ("interactive", "non-interactive")
RUNTIMES = ("docker", "apptainer", "singularity")
OUTPUT_FOLDERNAME = "bloodstream"
REMOTE_IMAGE_PREFIXES = ("docker://", "library://", "oras://", "shub://")
MISSING_IMAGE = "Image '{}' is missing\nWould you like to download? [Y/n] "


class BloodstreamHelpFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
    """Preserve paragraphs while still showing defaults."""


class PathAction(argparse.Action):
    """Expand user paths while preserving argparse's standard display."""

    def __call__(self, parser, namespace, values, option_string=None):
        if values is None:
            setattr(namespace, self.dest, None)
            return
        if isinstance(values, list):
            setattr(namespace, self.dest, [str(Path(value).expanduser()) for value in values])
        else:
            setattr(namespace, self.dest, str(Path(values).expanduser()))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="bloodstream-docker",
        formatter_class=BloodstreamHelpFormatter,
        description=(
            "The bloodstream on Docker/Apptainer wrapper\n\n"
            "This is a lightweight Python wrapper to run bloodstream in a container. "
            "For Docker, Docker must be installed and running. This can be checked running::\n\n"
            "    docker info\n\n"
            "The wrapper accepts a BIDS-App-like command line and translates host "
            "paths into container bind mounts before executing the bloodstream image. "
            "Pass --apptainer to emit an 'apptainer run' command instead of 'docker run'."
        ),
    )

    parser.add_argument("bids_dir", nargs="?", action=PathAction)
    parser.add_argument("output_dir", nargs="?", action=PathAction)
    parser.add_argument("analysis_level", nargs="?", choices=("participant",), default="participant")
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    parser.add_argument(
        "-i",
        "--image",
        help=(
            "image name; defaults to '"
            + DEFAULT_IMAGE
            + "' for Docker and './"
            + DEFAULT_SIF
            + "' for Apptainer (a docker:// URI also works with Apptainer)"
        ),
    )

    wrapper = parser.add_argument_group(
        "Wrapper options",
        "Standard options that require mapping files into the container; see bloodstream usage for complete descriptions",
    )
    wrapper.add_argument(
        "--mode",
        choices=MODES,
        default="interactive",
        help=(
            "execution mode: 'interactive' launches the Shiny config app, "
            "'non-interactive' runs the pipeline; or use the "
            "--interactive / --automatic shorthands below"
        ),
    )
    wrapper.add_argument(
        "--interactive",
        dest="mode",
        action="store_const",
        const="interactive",
        default=argparse.SUPPRESS,
        help="shorthand for --mode interactive (launch the Shiny config app in the browser)",
    )
    wrapper.add_argument(
        "--automatic",
        "--non-interactive",
        dest="mode",
        action="store_const",
        const="non-interactive",
        default=argparse.SUPPRESS,
        help="shorthand for --mode non-interactive (run the processing pipeline)",
    )
    wrapper.add_argument(
        "--config",
        action=PathAction,
        help=(
            "bloodstream config JSON file to use; mounted into the container at "
            "/config.json. Without one, the pipeline falls back to linear "
            "interpolation of the measured data"
        ),
    )
    wrapper.add_argument(
        "--analysis-foldername",
        default="Primary_Analysis",
        help=(
            "name of the analysis subfolder within derivatives/bloodstream holding "
            "this run's config, report and outputs; multiple can sit side by side, "
            "e.g. 'Model_AIF', 'Linear_Interpolation'"
        ),
    )
    wrapper.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help="host and container port for the interactive Shiny app",
    )

    container = parser.add_argument_group(
        "Container runtime options",
        "Choose between Docker (desktops, servers) and Apptainer (HPC clusters)",
    )
    container.add_argument(
        "--container",
        choices=RUNTIMES,
        default="docker",
        help="container runtime to generate a command for; 'singularity' runs the same command through the singularity executable",
    )
    container.add_argument(
        "--apptainer",
        dest="container",
        action="store_const",
        const="apptainer",
        default=argparse.SUPPRESS,
        help="shorthand for --container apptainer",
    )
    container.add_argument(
        "--no-cleanenv",
        action="store_true",
        help="Apptainer only: do not pass --cleanenv, letting the host environment through to the container",
    )

    developer = parser.add_argument_group("Developer options", "Tools for testing and debugging bloodstream")
    developer.add_argument("--shell", action="store_true", help="open shell in image instead of running bloodstream")
    developer.add_argument(
        "-f",
        "--patch",
        action=PathAction,
        help="local bloodstream checkout to install over the image's bloodstream at "
        "container start (for testing local changes without rebuilding the image)",
    )
    developer.add_argument(
        "-e",
        "--env",
        nargs=2,
        action="append",
        metavar=("ENV_VAR", "value"),
        help="set custom environment variables within container",
    )
    developer.add_argument(
        "-u",
        "--user",
        help="Docker only: run container as a given user/uid. A group/gid can also be assigned, "
        "i.e. --user <UID>:<GID>. On Linux, --user $(id -u):$(id -g) makes the outputs yours "
        "if your UID is not the image's default of 1000",
    )
    developer.add_argument("--network", help='Docker only: run container with a different network driver, e.g. "none"')
    developer.add_argument(
        "--platform",
        default=DEFAULT_PLATFORM,
        help="Docker only: run Docker with a specific platform; bloodstream images are currently published for linux/amd64",
    )
    developer.add_argument("--no-tty", action="store_true", help="Docker only: run docker without TTY flag -it")
    developer.add_argument("--dry-run", action="store_true", help="print the container command without executing it")
    developer.add_argument(
        "--skip-image-check",
        action="store_true",
        help="do not check whether the container image exists before running",
    )

    return parser


def _absolute_path(path: Optional[str], *, create: bool = False) -> Optional[str]:
    if path is None:
        return None

    resolved = Path(path).expanduser().absolute()
    if create:
        resolved.mkdir(parents=True, exist_ok=True)
    return str(resolved)


def _derivatives_mount_from_output(output_dir: str) -> str:
    """Map BIDS-App-like output_dir to bloodstream's derivatives mount point.

    bloodstream's container entry point expects the derivatives root and then
    writes into ``bloodstream/<analysis_foldername>`` inside it. If the wrapper
    user passes the final bloodstream output directory, such as
    ``derivatives/bloodstream``, mount its parent so the outputs do not end up
    in ``bloodstream/bloodstream``.
    """

    output_path = Path(output_dir)
    if output_path.name == OUTPUT_FOLDERNAME:
        return str(output_path.parent)
    return output_dir


def _mount_argument(host_path: str, container_path: str, mode: str) -> str:
    return f"{host_path}:{container_path}:{mode}"


def resolve_image(opts: argparse.Namespace) -> str:
    """Return the image to run, defaulting per container runtime."""

    if opts.image:
        return opts.image
    return DEFAULT_IMAGE if opts.container == "docker" else DEFAULT_SIF


def runtime_executable(container: str) -> str:
    """Return the executable driving a given container runtime."""

    return "docker" if container == "docker" else container


def _note_ignored_docker_options(opts: argparse.Namespace) -> None:
    ignored = []
    if opts.user:
        ignored.append("--user")
    if opts.network:
        ignored.append("--network")
    if ignored:
        print(
            "Note: " + ", ".join(ignored) + " apply to Docker only and are ignored by "
            f"{opts.container}, which runs as the invoking user on the host network.",
            file=sys.stderr,
        )


def _image_arguments(opts: argparse.Namespace) -> List[str]:
    arguments = [
        "--mode",
        opts.mode,
        "--analysis_foldername",
        opts.analysis_foldername,
    ]
    if opts.config:
        arguments.extend(["--config", "/config.json"])
    return arguments


def build_container_command(opts: argparse.Namespace) -> List[str]:
    """Build the Docker or Apptainer command corresponding to parsed options."""

    if opts.mode == "interactive" and (opts.port < 1 or opts.port > 65535):
        raise SystemExit("--port must be between 1 and 65535")

    bids_dir = _absolute_path(opts.bids_dir) if opts.bids_dir else None
    output_dir = _absolute_path(opts.output_dir, create=not opts.shell) if opts.output_dir else None
    derivatives_dir = _derivatives_mount_from_output(output_dir) if output_dir else None

    config_file = _absolute_path(opts.config) if opts.config else None
    if config_file and not Path(config_file).is_file():
        raise SystemExit(f"--config must point to an existing config file: {config_file}")

    if not opts.shell:
        missing = []
        if not bids_dir:
            missing.append("bids_dir")
        if not output_dir:
            missing.append("output_dir")

        if opts.mode == "non-interactive" and missing:
            raise SystemExit(
                "the following arguments are required in non-interactive mode: " + ", ".join(missing)
            )
        # Interactive mode can create a config with no data at all, but the app
        # can only run the pipeline if it has somewhere to write its outputs.
        if bids_dir and not output_dir:
            raise SystemExit(
                "output_dir is required when bids_dir is given, so the app can write its outputs"
            )

    if opts.container == "docker":
        command = _docker_command(opts, bids_dir, derivatives_dir, config_file)
    else:
        _note_ignored_docker_options(opts)
        command = _apptainer_command(opts, bids_dir, derivatives_dir, config_file)

    return command


def _docker_command(
    opts: argparse.Namespace,
    bids_dir: Optional[str],
    derivatives_dir: Optional[str],
    config_file: Optional[str],
) -> List[str]:
    command = ["docker", "run", "--rm"]
    if opts.platform:
        command.extend(["--platform", opts.platform])
    if not opts.no_tty:
        command.append("-it")

    if opts.user:
        command.extend(["--user", opts.user])
    if opts.network:
        command.extend(["--network", opts.network])

    env = list(opts.env or [])
    if opts.mode == "interactive":
        env.append(("BLOODSTREAM_SHINY_PORT", str(opts.port)))
        env.append(("SHINY_SERVER_VERSION", ""))
        command.extend(["-p", f"{opts.port}:{opts.port}"])

    for key, value in env:
        command.extend(["-e", f"{key}={value}"])

    for host_path, container_path, mode in _mounts(opts, bids_dir, derivatives_dir, config_file):
        command.extend(["-v", _mount_argument(host_path, container_path, mode)])

    image = resolve_image(opts)
    if opts.shell:
        command.extend(["--entrypoint", "/bin/bash", image])
        return command

    command.append(image)
    command.extend(_image_arguments(opts))
    return command


def _apptainer_command(
    opts: argparse.Namespace,
    bids_dir: Optional[str],
    derivatives_dir: Optional[str],
    config_file: Optional[str],
) -> List[str]:
    executable = runtime_executable(opts.container)
    command = [executable, "shell" if opts.shell else "run"]
    if not opts.no_cleanenv:
        command.append("--cleanenv")

    env = list(opts.env or [])
    if opts.mode == "interactive" and not opts.shell:
        # Apptainer shares the host network, so there is no port to publish: the
        # app is reached on whichever port it binds inside the container.
        env.append(("BLOODSTREAM_SHINY_PORT", str(opts.port)))

    for key, value in env:
        command.extend(["--env", f"{key}={value}"])

    for host_path, container_path, mode in _mounts(opts, bids_dir, derivatives_dir, config_file):
        command.extend(["-B", _mount_argument(host_path, container_path, mode)])

    # Quarto rendering and the patch install both write under /tmp, which
    # Apptainer does not always share with the host by default.
    command.extend(["-B", "/tmp:/tmp"])

    command.append(resolve_image(opts))
    if not opts.shell:
        command.extend(_image_arguments(opts))
    return command


def _mounts(
    opts: argparse.Namespace,
    bids_dir: Optional[str],
    derivatives_dir: Optional[str],
    config_file: Optional[str],
) -> List[tuple]:
    mounts = []
    if bids_dir:
        mounts.append((bids_dir, "/data/bids_dir", "ro"))
    if derivatives_dir:
        mounts.append((derivatives_dir, "/data/derivatives_dir", "rw"))
    if config_file:
        mounts.append((config_file, "/config.json", "ro"))

    patch_dir = _absolute_path(opts.patch) if opts.patch else None
    if patch_dir:
        mounts.append((patch_dir, "/patch/bloodstream", "ro"))
    return mounts


def check_docker() -> None:
    """Fail early if Docker is unavailable, preserving Docker's own message."""

    try:
        subprocess.run(["docker", "info"], capture_output=True, text=True, check=True)
    except OSError as error:
        raise SystemExit(f"Could not run Docker: {error}") from error
    except subprocess.CalledProcessError as error:
        docker_output = (error.stderr or error.stdout or "").strip()
        if docker_output:
            print(docker_output, file=sys.stderr)
        print("Could not detect memory capacity of Docker container.", file=sys.stderr)
        raise SystemExit("Do you have permission to run docker?") from error

    return None


def check_apptainer(executable: str = "apptainer") -> None:
    """Fail early if the Apptainer/Singularity executable is unavailable."""

    try:
        subprocess.run([executable, "--version"], capture_output=True, text=True, check=True)
    except OSError as error:
        raise SystemExit(
            f"Could not run {executable}: {error}\n"
            f"On an HPC cluster it usually needs loading first, e.g. 'module load {executable}'."
        ) from error
    except subprocess.CalledProcessError as error:
        output = (error.stderr or error.stdout or "").strip()
        if output:
            print(output, file=sys.stderr)
        raise SystemExit(f"Could not run {executable}") from error

    return None


def image_exists(image: str) -> bool:
    """Return whether a Docker image is available locally."""

    try:
        result = subprocess.run(["docker", "images", "-q", image], stdout=subprocess.PIPE)
    except OSError:
        return False
    return bool(result.stdout)


def check_memory(image: str, platform: Optional[str] = DEFAULT_PLATFORM) -> int:
    """Return available container memory in MB, or -1 if Docker cannot report it."""

    command = ["docker", "run", "--rm"]
    if platform:
        command.extend(["--platform", platform])
    command.extend(["--entrypoint=free", image, "-m"])

    try:
        result = subprocess.run(command, stdout=subprocess.PIPE)
    except OSError:
        return -1

    if result.returncode:
        return -1

    for line in result.stdout.splitlines():
        if line.startswith(b"Mem:"):
            return int(line.decode().split()[1])
    return -1


def maybe_pull_image(image: str) -> None:
    """Offer to download a missing image before Docker pulls via ``docker run``."""

    if image_exists(image):
        return

    answer = input(MISSING_IMAGE.format(image))
    if answer.strip().lower() not in ("", "y", "yes"):
        raise SystemExit(f"Image '{image}' is required")

    print("Downloading. This may take a while...", flush=True)


def ensure_image_ready(image: str, platform: Optional[str] = DEFAULT_PLATFORM) -> None:
    """Confirm image availability and that Docker can run a tiny memory probe."""

    maybe_pull_image(image)
    if check_memory(image, platform=platform) == -1:
        print("Could not detect memory capacity of Docker container.", file=sys.stderr)
        raise SystemExit("Do you have permission to run docker?")


def ensure_sif_ready(image: str) -> None:
    """Confirm a local SIF file exists, leaving remote URIs to Apptainer."""

    if image.startswith(REMOTE_IMAGE_PREFIXES):
        return

    if not Path(image).expanduser().exists():
        raise SystemExit(
            f"Image '{image}' was not found.\n"
            "Build it from the published Docker image with:\n\n"
            f"    apptainer build {image} docker://{DEFAULT_IMAGE}\n\n"
            f"or point at a different one with --image, including a docker:// URI."
        )


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = _parser()
    opts = parser.parse_args(argv)

    image = resolve_image(opts)

    if not opts.dry_run:
        if opts.container == "docker":
            check_docker()
            if not opts.skip_image_check:
                ensure_image_ready(image, platform=opts.platform)
        else:
            check_apptainer(runtime_executable(opts.container))
            if not opts.skip_image_check:
                ensure_sif_ready(image)

    command = build_container_command(opts)
    print("RUNNING: " + shlex.join(command))

    if opts.dry_run:
        return 0
    return subprocess.call(command)
