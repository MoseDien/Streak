import ProjectDescription

let project = Project(
    name: "StreakDaily",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
            "DEVELOPMENT_TEAM": "4V4QEMAAYL",
            "CODE_SIGN_STYLE": "Automatic"
        ]
    ),
    targets: [
        .target(
            name: "StreakDaily",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.dienbell.streak",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Streak Daily",
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"]
            ]),
            sources: ["StreakDaily/**/*.swift"],
            resources: ["StreakDaily/Resources/**"],
            dependencies: [],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"
            ])
        ),
        .target(
            name: "StreakDailyTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.dienbell.streak.tests",
            deploymentTargets: .iOS("26.0"),
            sources: ["StreakDailyTests/**"],
            dependencies: [
                .target(name: "StreakDaily")
            ]
        )
    ]
)
