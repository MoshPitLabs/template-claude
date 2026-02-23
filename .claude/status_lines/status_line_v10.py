#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "python-dotenv",
# ]
# ///

"""
Status Line v10 - Context Window Usage with Git Branch
Display: [Model] # [###---] | 42.5% used | ~115k left | branch-name
Visual progress indicator with percentage and current git branch
"""

import json
import subprocess
import sys

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass  # dotenv is optional


# ANSI color codes
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
BRIGHT_WHITE = "\033[97m"
DIM = "\033[90m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
RESET = "\033[0m"


def get_usage_color(percentage):
    """Get color based on usage percentage."""
    if percentage < 50:
        return GREEN
    elif percentage < 75:
        return YELLOW
    elif percentage < 90:
        return RED
    else:
        return "\033[91m"  # Bright red for critical


def create_progress_bar(percentage, width=15):
    """Create a visual progress bar."""
    filled = int((percentage / 100) * width)
    empty = width - filled

    color = get_usage_color(percentage)

    bar = f"{color}{'#' * filled}{DIM}{'-' * empty}{RESET}"
    return f"[{bar}]"


def format_tokens(tokens):
    """Format token count in human-readable format."""
    if tokens is None:
        return "0"
    if tokens < 1000:
        return str(int(tokens))
    elif tokens < 1000000:
        return f"{tokens / 1000:.1f}k"
    else:
        return f"{tokens / 1000000:.2f}M"


def get_git_branch():
    """Get the current git branch name."""
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        branch = result.stdout.strip()
        return branch if branch else "HEAD"
    except Exception:
        return ""


def generate_status_line(input_data):
    """Generate the context window usage status line."""
    # Get model name
    model_info = input_data.get("model", {})
    model_name = model_info.get("display_name", "Claude")

    # Get context window data
    context_data = input_data.get("context_window", {})
    used_percentage = context_data.get("used_percentage", 0) or 0
    context_window_size = context_data.get("context_window_size", 200000) or 200000

    # Calculate remaining tokens from used percentage
    remaining_tokens = int(context_window_size * ((100 - used_percentage) / 100))

    # Get color for percentage display
    usage_color = get_usage_color(used_percentage)

    # Build status line
    parts = []

    # Model name in cyan
    parts.append(f"{CYAN}[{model_name}]{RESET}")

    # Progress bar with hash indicator
    progress_bar = create_progress_bar(used_percentage)
    parts.append(f"{MAGENTA}#{RESET} {progress_bar}")

    # Used percentage
    parts.append(f"{usage_color}{used_percentage:.1f}%{RESET} used")

    # Tokens left
    tokens_left_str = format_tokens(remaining_tokens)
    parts.append(f"{BLUE}~{tokens_left_str} left{RESET}")

    # Git branch (rightmost)
    branch = get_git_branch()
    if branch:
        parts.append(f"{DIM}\ue0a0 {branch}{RESET}")

    return " | ".join(parts)


def main():
    try:
        input_data = json.loads(sys.stdin.read())
        status_line = generate_status_line(input_data)
        print(status_line)
        sys.exit(0)

    except json.JSONDecodeError:
        print(f"{RED}[Claude] # Error: Invalid JSON{RESET}")
        sys.exit(0)
    except Exception as e:
        print(f"{RED}[Claude] # Error: {str(e)}{RESET}")
        sys.exit(0)


if __name__ == "__main__":
    main()
