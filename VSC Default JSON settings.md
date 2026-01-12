{
  "gitlens.ai.model": "vscode",
  "gitlens.ai.vscode.model": "copilot:gpt-4.1",
  "editor.formatOnSave": true,
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true
  },
  "[terraform-vars]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true
  },
  "terraform.formatOnSave": true,
  "terraform.validateOnSave": true,
  "terraform.languageServer.enable": true,
  "security.workspace.trust.untrustedFiles": "open",
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.enableSmartCommit": true,
  "git.postCommitCommand": "sync",
  "diffEditor.ignoreTrimWhitespace": false,
  "gitlens.currentLine.enabled": false,
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": true,
  "gitlens.views.repositories.files.layout": "tree",
  "gitlens.views.searchAndCompare.enabled": true,
  "terraform.experimentalFeatures.validateOnSave": true,
  "terraform.experimentalFeatures.prefillRequiredFields": true,
  "files.associations": {
    "*.tf": "terraform",
    "*.tfvars": "terraform-vars"
  },
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.profiles.windows": {
    "PowerShell": {
      "path": "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
    },
    "Command Prompt": {
      "path": [
        "${env:windir}\\Sysnative\\cmd.exe",
        "${env:windir}\\System32\\cmd.exe"
      ],
      "args": [],
      "icon": "terminal-cmd"
    },
    "Git Bash": {
      "source": "Git Bash",
      "icon": "terminal-git-bash"
    }
  }
}