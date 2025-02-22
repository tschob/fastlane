require 'fastlane_core/configuration/config_item'
require 'credentials_manager/appfile_config'
require_relative 'module'

module Gym
  class Options
    def self.available_options
      return @options if @options

      @options = plain_options
    end

    def self.plain_options
      [
        FastlaneCore::ConfigItem.new(key: :workspace,
                                     short_option: "-w",
                                     env_name: "GYM_WORKSPACE",
                                     optional: true,
                                     description: "Path to the workspace file",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Workspace file not found at path '#{v}'") unless File.exist?(v)
                                       UI.user_error!("Workspace file invalid") unless File.directory?(v)
                                       UI.user_error!("Workspace file is not a workspace, must end with .xcworkspace") unless v.include?(".xcworkspace")
                                     end,
                                     conflicting_options: [:project],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can only pass either a 'workspace' or a '#{value.key}', not both")
                                     end),
        FastlaneCore::ConfigItem.new(key: :project,
                                     short_option: "-p",
                                     optional: true,
                                     env_name: "GYM_PROJECT",
                                     description: "Path to the project file",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Project file not found at path '#{v}'") unless File.exist?(v)
                                       UI.user_error!("Project file invalid") unless File.directory?(v)
                                       UI.user_error!("Project file is not a project file, must end with .xcodeproj") unless v.include?(".xcodeproj")
                                     end,
                                     conflicting_options: [:workspace],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can only pass either a 'project' or a '#{value.key}', not both")
                                     end),
        FastlaneCore::ConfigItem.new(key: :scheme,
                                     short_option: "-s",
                                     optional: true,
                                     env_name: "GYM_SCHEME",
                                     description: "The project's scheme. Make sure it's marked as `Shared`"),
        FastlaneCore::ConfigItem.new(key: :clean,
                                     short_option: "-c",
                                     env_name: "GYM_CLEAN",
                                     description: "Should the project be cleaned before building it?",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :output_directory,
                                     short_option: "-o",
                                     env_name: "GYM_OUTPUT_DIRECTORY",
                                     description: "The directory in which the ipa file should be stored in",
                                     default_value: "."),
        FastlaneCore::ConfigItem.new(key: :output_name,
                                     short_option: "-n",
                                     env_name: "GYM_OUTPUT_NAME",
                                     description: "The name of the resulting ipa file",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :configuration,
                                     short_option: "-q",
                                     env_name: "GYM_CONFIGURATION",
                                     description: "The configuration to use when building the app. Defaults to 'Release'",
                                     default_value_dynamic: true,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :silent,
                                     short_option: "-a",
                                     env_name: "GYM_SILENT",
                                     description: "Hide all information that's not necessary while building",
                                     default_value: false,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :codesigning_identity,
                                     short_option: "-i",
                                     env_name: "GYM_CODE_SIGNING_IDENTITY",
                                     description: "The name of the code signing identity to use. It has to match the name exactly. e.g. 'iPhone Distribution: SunApps GmbH'",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_package_ipa,
                                     env_name: "GYM_SKIP_PACKAGE_IPA",
                                     description: "Should we skip packaging the ipa?",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_package_pkg,
                                     env_name: "GYM_SKIP_PACKAGE_PKG",
                                     description: "Should we skip packaging the pkg?",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :include_symbols,
                                     short_option: "-m",
                                     env_name: "GYM_INCLUDE_SYMBOLS",
                                     description: "Should the ipa file include symbols?",
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :include_bitcode,
                                     short_option: "-z",
                                     env_name: "GYM_INCLUDE_BITCODE",
                                     description: "Should the ipa file include bitcode?",
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :export_method,
                                     short_option: "-j",
                                     env_name: "GYM_EXPORT_METHOD",
                                     description: "Method used to export the archive. Valid values are: app-store, validation, ad-hoc, package, enterprise, development, developer-id and mac-application",
                                     type: String,
                                     optional: true,
                                     verify_block: proc do |value|
                                       av = %w(app-store validation ad-hoc package enterprise development developer-id mac-application)
                                       UI.user_error!("Unsupported export_method '#{value}', must be: #{av}") unless av.include?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :export_options,
                                     env_name: "GYM_EXPORT_OPTIONS",
                                     description: "Path to an export options plist or a hash with export options. Use 'xcodebuild -help' to print the full set of available options",
                                     optional: true,
                                     type: Hash,
                                     skip_type_validation: true,
                                     conflict_block: proc do |value|
                                       UI.user_error!("'#{value.key}' must be false to use 'export_options'")
                                     end),
        FastlaneCore::ConfigItem.new(key: :export_xcargs,
                                     env_name: "GYM_EXPORT_XCARGS",
                                     description: "Pass additional arguments to xcodebuild for the package phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS=\"-ObjC -lstdc++\"",
                                     optional: true,
                                     conflict_block: proc do |value|
                                       UI.user_error!("'#{value.key}' must be false to use 'export_xcargs'")
                                     end,
                                     type: :shell_string),
        FastlaneCore::ConfigItem.new(key: :skip_build_archive,
                                     env_name: "GYM_SKIP_BUILD_ARCHIVE",
                                     description: "Export ipa from previously built xcarchive. Uses archive_path as source",
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_archive,
                                     env_name: "GYM_SKIP_ARCHIVE",
                                     description: "After building, don't archive, effectively not including -archivePath param",
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_codesigning,
                                     env_name: "GYM_SKIP_CODESIGNING",
                                     description: "Build without codesigning",
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :catalyst_platform,
                                     env_name: "GYM_CATALYST_PLATFORM",
                                     description: "Platform to build when using a Catalyst enabled app. Valid values are: ios, macos",
                                     type: String,
                                     optional: true,
                                     verify_block: proc do |value|
                                       av = %w(ios macos)
                                       UI.user_error!("Unsupported export_method '#{value}', must be: #{av}") unless av.include?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :installer_cert_name,
                                     env_name: "GYM_INSTALLER_CERT_NAME",
                                     description: "Full name of 3rd Party Mac Developer Installer or Developer ID Installer certificate. Example: `3rd Party Mac Developer Installer: Your Company (ABC1234XWYZ)`",
                                     type: String,
                                     optional: true),
        # Very optional
        FastlaneCore::ConfigItem.new(key: :build_path,
                                     env_name: "GYM_BUILD_PATH",
                                     description: "The directory in which the archive should be stored in",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :archive_path,
                                     short_option: "-b",
                                     env_name: "GYM_ARCHIVE_PATH",
                                     description: "The path to the created archive",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :derived_data_path,
                                     short_option: "-f",
                                     env_name: "GYM_DERIVED_DATA_PATH",
                                     description: "The directory where built products and other derived data will go",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :result_bundle,
                                     short_option: "-u",
                                     env_name: "GYM_RESULT_BUNDLE",
                                     type: Boolean,
                                     description: "Should an Xcode result bundle be generated in the output directory",
                                     default_value: false,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :result_bundle_path,
                                     env_name: "GYM_RESULT_BUNDLE_PATH",
                                     description: "Path to the result bundle directory to create. Ignored if `result_bundle` if false",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :buildlog_path,
                                     short_option: "-l",
                                     env_name: "GYM_BUILDLOG_PATH",
                                     description: "The directory where to store the build log",
                                     default_value: "#{FastlaneCore::Helper.buildlog_path}/gym",
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :sdk,
                                     short_option: "-k",
                                     env_name: "GYM_SDK",
                                     description: "The SDK that should be used for building the application",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :toolchain,
                                     env_name: "GYM_TOOLCHAIN",
                                     description: "The toolchain that should be used for building the application (e.g. com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a)",
                                     optional: true,
                                     type: String),
        FastlaneCore::ConfigItem.new(key: :destination,
                                     short_option: "-d",
                                     env_name: "GYM_DESTINATION",
                                     description: "Use a custom destination for building the app",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :export_team_id,
                                     short_option: "-g",
                                     env_name: "GYM_EXPORT_TEAM_ID",
                                     description: "Optional: Sometimes you need to specify a team id when exporting the ipa file",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :xcargs,
                                     short_option: "-x",
                                     env_name: "GYM_XCARGS",
                                     description: "Pass additional arguments to xcodebuild for the build phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS=\"-ObjC -lstdc++\"",
                                     optional: true,
                                     type: :shell_string),
        FastlaneCore::ConfigItem.new(key: :xcconfig,
                                     short_option: "-y",
                                     env_name: "GYM_XCCONFIG",
                                     description: "Use an extra XCCONFIG file to build your app",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("File not found at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :suppress_xcode_output,
                                     short_option: "-r",
                                     env_name: "SUPPRESS_OUTPUT",
                                     description: "Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path",
                                     optional: true,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :disable_xcpretty,
                                     env_name: "DISABLE_XCPRETTY",
                                     description: "Disable xcpretty formatting of build output",
                                     optional: true,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :xcpretty_test_format,
                                     env_name: "XCPRETTY_TEST_FORMAT",
                                     description: "Use the test (RSpec style) format for build output",
                                     optional: true,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :xcpretty_formatter,
                                     env_name: "XCPRETTY_FORMATTER",
                                     description: "A custom xcpretty formatter to use",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Formatter file not found at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :xcpretty_report_junit,
                                     env_name: "XCPRETTY_REPORT_JUNIT",
                                     description: "Have xcpretty create a JUnit-style XML report at the provided path",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :xcpretty_report_html,
                                     env_name: "XCPRETTY_REPORT_HTML",
                                     description: "Have xcpretty create a simple HTML report at the provided path",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :xcpretty_report_json,
                                     env_name: "XCPRETTY_REPORT_JSON",
                                     description: "Have xcpretty create a JSON compilation database at the provided path",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :analyze_build_time,
                                     env_name: "GYM_ANALYZE_BUILD_TIME",
                                     description: "Analyze the project build time and store the output in 'culprits.txt' file",
                                     optional: true,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :xcpretty_utf,
                                     env_name: "XCPRETTY_UTF",
                                     description: "Have xcpretty use unicode encoding when reporting builds",
                                     optional: true,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :skip_profile_detection,
                                     env_name: "GYM_SKIP_PROFILE_DETECTION",
                                     description: "Do not try to build a profile mapping from the xcodeproj. Match or a manually provided mapping should be used",
                                     optional: true,
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :cloned_source_packages_path,
                                     env_name: "GYM_CLONED_SOURCE_PACKAGES_PATH",
                                     description: "Sets a custom path for Swift Package Manager dependencies",
                                     type: String,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_package_dependencies_resolution,
                                     env_name: "GYM_SKIP_PACKAGE_DEPENDENCIES_RESOLUTION",
                                     description: "Skips resolution of Swift Package Manager dependencies",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :disable_package_automatic_updates,
                                     env_name: "GYM_DISABLE_PACKAGE_AUTOMATIC_UPDATES",
                                     description: "Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :use_system_scm,
                                     env_name: "GYM_USE_SYSTEM_SCM",
                                     description: "Lets xcodebuild use system's scm configuration",
                                     optional: true,
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :export_command_prefix,
                                    env_name: "GYM_XCODE_EXPORT_COMMAND_PREFIX",
                                    description: "Allows to prefix the export command call. Can be e.g. useful to change the architecture",
                                    type: String,
                                    optional: true)
      ]
    end
  end
end
