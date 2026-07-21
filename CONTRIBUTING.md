# Contributing to ProtonPlus

First off, thanks for taking the time to contribute! ❤️

All types of contributions are welcome. Read the relevant section below before starting so maintainers can review your contribution efficiently. 🎉

> And if you like the project, but just don't have time to contribute, that's fine. There are other easy ways to support the project and show your appreciation, which we would also be very happy about:
>
> - Star the project
> - Tweet about it
> - Refer this project in your project's readme
> - Mention the project at local meetups and tell your friends/colleagues

## Table of Contents

- [I Have a Question](#i-have-a-question)
- [Getting Started](#getting-started)
- [Development](#development)
  - [Building and Running](#building-and-running)
  - [Testing](#testing)
  - [Translations](#translations)
  - [Icons](#icons)
  - [Linting](#linting)
  - [Adding a Compatibility Tool or Launcher](#adding-a-compatibility-tool-or-launcher)
  - [Project Structure](#project-structure)
- [I Want To Contribute](#i-want-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Style Guide](#style-guide)
  - [Code Style](#code-style)

## Code of Conduct

This project and everyone participating in it is governed by the
[ProtonPlus Code of Conduct](https://github.com/Vysp3r/ProtonPlus/blob/main/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable behavior
to [@Vysp3r](https://github.com/Vysp3r).

## I Have a Question

> If you want to ask a question, we assume that you have read the available [Documentation](https://github.com/Vysp3r/ProtonPlus/#readme).

Before you ask a question, it is best to search for existing [Issues](https://github.com/Vysp3r/ProtonPlus/issues) that might help you. In case you have found a suitable issue and still need clarification, you can write your question in this issue. It is also advisable to search the internet for answers first.

If you then still feel the need to ask a question and need clarification, we recommend the following:

- Open an [Issue](https://github.com/Vysp3r/ProtonPlus/issues/new).
- Provide as much context as you can about what you're running into.

We will then take care of the issue as soon as possible.

## Getting Started

### Prerequisites

Install the dependencies listed in the [README](README.md#requirements) before building the project.

### Forking and Cloning

1. Fork the [ProtonPlus repository](https://github.com/Vysp3r/ProtonPlus/fork).
2. Clone your fork locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/ProtonPlus.git
   cd ProtonPlus
   ```

## Development

We use a helper script `scripts/build.sh` to simplify common development tasks.

### Building and Running

#### Native Build

To build and run the application natively on your system:

```bash
./scripts/build.sh native run
```

#### Flatpak Build

To build and run using the local Flatpak manifest:

```bash
./scripts/build.sh local run
```

### Testing

Configure, compile, and run all tests with:

```bash
make tests
```

### Translations

ProtonPlus uses [Weblate](https://hosted.weblate.org/projects/protonplus/protonplus/) for translations. You can contribute there or modify the `.po` files in the `po/` directory directly.

To update the translation files after changing the source code:

```bash
./scripts/build.sh translations
```

### Icons

If you need to regenerate icons from the SVG source:

```bash
./scripts/build.sh icons
```

### Linting

To run the Flathub linter on the local source:

```bash
./scripts/build.sh linter
```

### Cleaning Up

To remove all build-related directories:

```bash
./scripts/build.sh clean
```

### Adding a Compatibility Tool or Launcher

Compatibility tools are implemented under `src/models/launchers/runners/`; launchers are implemented under `src/models/launchers/`.

1. Locate a similar existing implementation and follow its model and request patterns.
2. Add the new source file to the nearest `meson.build` file.
3. Register the implementation in the appropriate launcher or runner collection.
4. Build the application and run `make tests`.
5. Update translations with `./scripts/build.sh translations` if user-facing text changed.

### Project Structure

To help you navigate the codebase, here's a quick overview of the project structure:

- `src/`: The Vala source code for the application.
  - `src/cli/`: Command-line interface logic.
  - `src/models/`: Core data models and business logic.
  - `src/utils/vdf/`: Valve Data Format (VDF) parser and models.
  - `src/widgets/`: GTK4 and Libadwaita UI widgets.
  - `src/utils/`: Utility functions and helper classes.
- `data/`: Asset files and UI definitions.
  - `data/ui/`: GTK XML UI definition files.
  - `data/icons/`: Application icons (hicolor) and symbolic UI icons.
- `po/`: Translation files (.po).
- `scripts/`: Helper scripts for build, translations, and maintenance.
- `tests/`: Vala unit tests and maintenance-script tests.

## I Want To Contribute

> ### Legal Notice
> When contributing to this project, you must agree that you have authored 100% of the content, that you have the necessary rights to the content and that the content you contribute may be provided under the project license.

### Reporting Bugs

#### Before Submitting a Bug Report

A good bug report shouldn't leave others needing to chase you up for more information. Therefore, we ask you to investigate carefully, collect information and describe the issue in detail in your report. Please complete the following steps in advance to help us fix any potential bug as fast as possible.

- Make sure that you are using the latest version.
- Confirm that the problem is not caused by an unsupported or incompatible environment. Read the [documentation](https://github.com/Vysp3r/ProtonPlus/#readme) and check the [questions section](#i-have-a-question) if you need support.
- Search the [bug tracker](https://github.com/Vysp3r/ProtonPlus/issues?q=is%3Aopen+is%3Aissue+label%3Abug) for an existing report.
- Also make sure to search the internet (including Stack Overflow) to see if users outside of the GitHub community have discussed the issue.
- Collect information about the bug:
  - Relevant log output or a stack trace
  - Distribution, desktop environment, installation type, and application version
  - Steps and input needed to reproduce the problem
  - Whether the problem is reproducible on earlier versions

#### How Do I Submit a Good Bug Report?

> Never report security-related issues or sensitive information publicly. Follow the [security policy](SECURITY.md) instead.

We use GitHub issues to track bugs and errors. If you run into an issue with the project:

- Open an [Issue](https://github.com/Vysp3r/ProtonPlus/issues/new).
- Explain the behavior you would expect and the actual behavior.
- Please provide as much context as possible and describe the *reproduction steps* that someone else can follow to recreate the issue on their own. This usually includes your code. For good bug reports you should isolate the problem and create a reduced test case.
- Provide the information you collected in the previous section.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for ProtonPlus, **including completely new features and minor improvements to existing functionality**. Following these guidelines will help maintainers and the community to understand your suggestion and find related suggestions.

#### Before Submitting an Enhancement

- Make sure that you are using the latest version.
- Read the [documentation](https://github.com/Vysp3r/ProtonPlus/#readme) carefully and find out if the functionality is already covered, maybe by an individual configuration.
- Perform a [search](https://github.com/Vysp3r/ProtonPlus/issues) to see if the enhancement has already been suggested. If it has, add a comment to the existing issue instead of opening a new one.
- Find out whether your idea fits with the scope and aims of the project. It's up to you to make a strong case to convince the project's developers of the merits of this feature. Keep in mind that we want features that will be useful to the majority of our users and not just a small subset. If you're just targeting a minority of users, consider writing an add-on/plugin library.

#### How Do I Submit a Good Enhancement Suggestion?

Enhancement suggestions are tracked as [GitHub issues](https://github.com/Vysp3r/ProtonPlus/issues).

- Use a **clear and descriptive title** for the issue to identify the suggestion.
- Provide a **step-by-step description of the suggested enhancement** in as many details as possible.
- **Describe the current behavior** and **explain which behavior you expected to see instead** and why. At this point you can also tell which alternatives do not work for you.
- You may want to **include screenshots or recordings** that demonstrate the workflow or relevant interface.
- **Explain why this enhancement would be useful** to most ProtonPlus users. You may also want to point out the other projects that solved it better and which could serve as inspiration.

### Pull Requests

Before submitting a Pull Request, please ensure you've:

1. **Checked for duplicates**: Make sure there's no existing PR covering your changes.
2. **Followed the style guide**: Your code should be well-formatted and easy to read.
3. **Tested your changes**: Run the application and `make tests`.
4. **Updated documentation**: If your changes add new functionality or configuration, update the relevant documentation.
5. **Updated translations**: If you've modified UI text, run `./scripts/build.sh translations` to update the PO files.

When opening a PR, please use the provided [Pull Request Template](.github/pull_request_template.md).

## Style Guide

### Code Style

ProtonPlus is written in Vala and generally follows the [Vala Style Guide](https://wiki.gnome.org/Projects/Vala/StyleGuide).

Key points:

- Use four **spaces** for Vala and Python indentation.
- Follow `.editorconfig` for other file types.
- Follow the existing coding patterns in the codebase.
- Aim for clear, self-documenting code.

---

Once again, thank you for your interest in contributing to ProtonPlus! 🚀
