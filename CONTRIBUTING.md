# Contributing to Trigger Myth Framework

First off, thank you for considering contributing to the Trigger Myth Framework! It's people like you that make this framework a great tool for the Roblox Myth community.

## Code of Conduct

All of our projects adhere to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). When participating, you are expected to honor this code.

## Where do I go from here?

If you've noticed a bug or have a feature request, make one! It's generally best if you get confirmation of your bug or approval for your feature request before starting to code.

### Found a Bug?
* **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/foecakes/TriggerMythFramework/issues).
* If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/foecakes/TriggerMythFramework/issues/new). Be sure to include a title and clear description, as much relevant information as possible, and a code sample or an executable test case demonstrating the expected behavior that is not occurring.

### Have a Feature Request?
* Open a new [Issue](https://github.com/foecakes/TriggerMythFramework/issues/new) and describe your feature request.
* Explain *why* this feature would be useful for the framework.
* If you want to build it yourself, please state that so we can discuss the implementation before you start.

## Development Setup

If you want to contribute code to the framework, here is how you can set up your local development environment:

### 1. Prerequisites

A code editor like VS Code with the [Luau LSP extension](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp) is recommended. You will also need to install **Rojo** (for syncing files to Roblox Studio) and **Wally** (for package management).

#### Installing Rojo
Rokit is the recommended toolchain manager for Roblox projects. To install the latest release of Rojo, run:
```bash
rokit add rojo-rbx/rojo
rokit install
```
Once you've installed the Rojo server, you can use it to install or upgrade the Rojo plugin for Roblox Studio from the command line:
```bash
rojo plugin install
```

#### Installing Wally
Aftman is the recommended toolchain manager for installing Wally. Run the following in your terminal:
```bash
aftman init
aftman add UpliftGames/wally
aftman install
```

### 2. Clone the repository:
```bash
git clone https://github.com/foecakes/TriggerMythFramework.git
cd TriggerMythFramework
```

### 3. Install dependencies:
```bash
wally install
```

### 4. Sync with Roblox Studio:
Run Rojo to sync the project into a blank Roblox place:
```bash
rojo serve
```
Then connect via the Rojo plugin in Roblox Studio.

## Code Style & Guidelines

* **Luau:** All new code must be written in strongly-typed Luau. Please include type annotations where possible (`local function DoSomething(part: BasePart): boolean`).
* **Knit:** This framework relies heavily on [Knit](https://sleitnick.github.io/Knit/). Please ensure new services or controllers follow Knit's architectural standards.
* **Documentation:** Any new utility functions or API additions must be documented. We use standard comment documentation (and maintain the `readme.lua` and `README.md` files).
* **Naming Conventions:**
  * Variables and properties should generally be `camelCase`.
  * Services, Controllers, and utility functions should be `PascalCase`.
  * Constants should be `UPPER_SNAKE_CASE`.

## Pull Requests

1. **Create a new branch** from `main` (e.g., `feature/awesome-new-trigger` or `bugfix/fix-chat-listener`).
2. **Make your changes** and test them thoroughly in Roblox Studio.
3. **Commit your changes** with a descriptive commit message.
4. **Push your branch** to your fork or the main repository.
5. **Open a Pull Request** against the `main` branch. Provide a clear description of the problem you're solving and how you solved it.

> **⚠️ WARNING: Security & 3rd-Party Branches**
> Please be extremely careful when downloading, testing, or reviewing branches made by 3rd parties. Always review the code before executing it in your local environment. 
> **Any attempts at including malicious code in branches, forks, or pull requests will result in an immediate ban and blacklist from the Stop Killing Myths organization.**

## License & Forking

This project is open-source and released under the Apache 2.0 License. Anyone is completely free and encouraged to fork this repository, modify the code, and use it in their own projects in accordance with the license!

Thank you for contributing!
