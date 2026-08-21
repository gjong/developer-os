import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: root
    width: 980
    height: 660
    minimumWidth: 860
    minimumHeight: 560
    visible: true
    title: "Welcome to Developer OS"
    color: "#0b1020"

    property int pageIndex: 0
    property var pages: [
        {
            kicker: "First hour",
            title: "Welcome Developer",
            subtitle: "Developer OS is set up for Java, .NET, and web work. Runtimes are not baked into the ISO; install them once with the bootstrap command, then open an IDE.",
            accent: "#7c3aed",
            command: "developer-os-bootstrap",
            bullets: [
                "Git, Docker, Firefox, vfox, and JetBrains Toolbox are already installed.",
                "Run `developer-os-bootstrap` (or Install language runtimes from the launcher) to get Java 21, Node LTS, .NET LTS, Maven, and Gradle.",
                "Needs network. Open a new terminal afterwards so `java`, `node`, and `dotnet` are on PATH."
            ]
        },
        {
            kicker: "Java",
            title: "Java",
            subtitle: "After bootstrap, JDK 21, Maven, and Gradle are on PATH. Install IntelliJ IDEA from JetBrains Toolbox for a full IDE.",
            accent: "#f97316",
            command: "java -version && mvn -version",
            bullets: [
                "Bootstrap installs `java@21`, `maven`, and `gradle` through vfox.",
                "Open Toolbox and install IntelliJ IDEA (Community or Ultimate).",
                "Pin a project with `vfox use -p java@21` in the repo, or keep the global default."
            ]
        },
        {
            kicker: ".NET",
            title: ".NET",
            subtitle: "After bootstrap, the .NET SDK is on PATH. Install Rider from JetBrains Toolbox for C# and ASP.NET work. Azure CLI is already installed.",
            accent: "#38bdf8",
            command: "dotnet --info",
            bullets: [
                "Bootstrap installs the .NET LTS SDK (`dotnet@8`, or another LTS if 8 is unavailable).",
                "Open Toolbox and install Rider.",
                "Sign in with `az login` when you work with Azure."
            ]
        },
        {
            kicker: "Web",
            title: "Web",
            subtitle: "After bootstrap, Node.js LTS is on PATH with npm, and pnpm via corepack when possible. Install WebStorm from Toolbox, or use Firefox and Brave for browser testing.",
            accent: "#22c55e",
            command: "node -v && npm -v",
            bullets: [
                "Bootstrap installs `nodejs` LTS and tries to activate pnpm with `corepack`.",
                "Open Toolbox and install WebStorm.",
                "Use `vfox use -p nodejs@22` (or your project's version) inside a repo."
            ]
        },
        {
            kicker: "IDEs",
            title: "JetBrains Toolbox",
            subtitle: "JetBrains Toolbox installs and updates IDEs from one place: IntelliJ IDEA, Rider, WebStorm, and others.",
            accent: "#a78bfa",
            command: "jetbrains-toolbox",
            bullets: [
                "Open Toolbox from the application launcher or run `jetbrains-toolbox`.",
                "Sign in with your JetBrains account to sync licenses and settings.",
                "Install IntelliJ IDEA for Java, Rider for .NET, or WebStorm for web work."
            ]
        },
        {
            kicker: "GitHub",
            title: "GitHub CLI",
            subtitle: "The `gh` command brings pull requests, issues, releases, and authentication into your terminal. `git` and `git-lfs` are installed.",
            accent: "#22c55e",
            command: "gh auth login",
            bullets: [
                "Authenticate once with `gh auth login`.",
                "Clone with `gh repo clone owner/name` or `git clone git@github.com:owner/name.git` (OpenSSH is installed).",
                "Create pull requests with `gh pr create` and review checks with `gh pr checks`."
            ]
        },
        {
            kicker: "Containers",
            title: "Docker",
            subtitle: "Docker, Buildx, and Docker Compose are installed and enabled for local services, containers, and reproducible build environments.",
            accent: "#60a5fa",
            command: "docker compose up",
            bullets: [
                "The Docker service starts on boot; your user is in the `docker` group.",
                "Run `docker run hello-world` to verify the daemon.",
                "Run `docker compose up` in projects that include a compose file."
            ]
        },
        {
            kicker: "Local AI",
            title: "Ollama",
            subtitle: "Ollama runs large language models locally. The service is enabled so you can pull and chat with models from the terminal.",
            accent: "#a78bfa",
            command: "ollama pull llama3.2 && ollama run llama3.2",
            bullets: [
                "The Ollama service starts on boot.",
                "Pull a model with `ollama pull <name>` (for example `llama3.2`).",
                "Chat with `ollama run <name>` or point apps at the local API on port 11434."
            ]
        }
    ]

    readonly property var currentPage: pages[pageIndex]

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#111827" }
            GradientStop { position: 0.48; color: "#111133" }
            GradientStop { position: 1.0; color: "#050816" }
        }
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.18
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: currentPage.accent }
            GradientStop { position: 0.44; color: "#00000000" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 34
        spacing: 22

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                width: 46
                height: 46
                radius: 14
                color: currentPage.accent

                Label {
                    anchors.centerIn: parent
                    text: "</>"
                    color: "white"
                    font.pixelSize: 17
                    font.bold: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: "Developer OS"
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                }

                Label {
                    text: "A short first-login tour of your installed tools"
                    color: "#aab4cf"
                    font.pixelSize: 14
                }
            }

            Button {
                text: "Close"
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 30
            color: "#f8fafc"
            border.color: "#ffffff"
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: 255
                    Layout.fillHeight: true
                    color: "#0f172a"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 26
                        spacing: 18

                        Label {
                            text: "Tour"
                            color: "#e2e8f0"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Repeater {
                            model: pages.length

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 54
                                radius: 16
                                color: index === pageIndex ? "#1e293b" : "transparent"
                                border.color: index === pageIndex ? pages[index].accent : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Rectangle {
                                        width: 13
                                        height: 13
                                        radius: 7
                                        color: pages[index].accent
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Label {
                                            text: pages[index].title
                                            color: "#f8fafc"
                                            font.pixelSize: 14
                                            font.bold: index === pageIndex
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            text: pages[index].kicker
                                            color: "#94a3b8"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: pageIndex = index
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Label {
                            Layout.fillWidth: true
                            text: "You can reopen this tour any time with:"
                            color: "#94a3b8"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 12
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 12
                            color: "#020617"

                            Label {
                                anchors.centerIn: parent
                                text: "developer-os-welcome --again"
                                color: "#c4b5fd"
                                font.family: "monospace"
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 46
                        spacing: 22

                        Label {
                            text: currentPage.kicker.toUpperCase()
                            color: currentPage.accent
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.8
                        }

                        Label {
                            Layout.fillWidth: true
                            text: currentPage.title
                            color: "#0f172a"
                            font.pixelSize: 44
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            Layout.fillWidth: true
                            text: currentPage.subtitle
                            color: "#475569"
                            font.pixelSize: 18
                            lineHeight: 1.15
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 72
                            radius: 18
                            color: "#0f172a"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 12

                                Label {
                                    text: "$"
                                    color: currentPage.accent
                                    font.family: "monospace"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: currentPage.command
                                    color: "#e2e8f0"
                                    font.family: "monospace"
                                    font.pixelSize: 15
                                    wrapMode: Text.WrapAnywhere
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Repeater {
                                model: currentPage.bullets

                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Rectangle {
                                        Layout.alignment: Qt.AlignTop
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: currentPage.accent

                                        Label {
                                            anchors.centerIn: parent
                                            text: index + 1
                                            color: "white"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData
                                        color: "#334155"
                                        font.pixelSize: 16
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Button {
                                text: "Back"
                                enabled: pageIndex > 0
                                onClicked: pageIndex = Math.max(0, pageIndex - 1)
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: (pageIndex + 1) + " of " + pages.length
                                color: "#64748b"
                                font.pixelSize: 13
                            }

                            Button {
                                text: pageIndex === pages.length - 1 ? "Finish" : "Next"
                                highlighted: true
                                onClicked: {
                                    if (pageIndex === pages.length - 1) {
                                        root.close()
                                    } else {
                                        pageIndex += 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
