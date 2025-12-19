# kmpkg completions for fish
set kmpkg_executable (string split -m1 ' ' (commandline -cb))[1]

function _kmpkg_completions
  set arg (string split -m1 ' ' (commandline -cb))[2]
  set curr_token (commandline -t)
  if [ -n $arg ]
    if [ -z $curr_token ]
      set arg $arg " "
    end
  end
  for key in ($kmpkg_executable autocomplete "$arg" -- 2>/dev/null)
    echo $key
  end
end

complete -c kmpkg -f --arguments '(_kmpkg_completions)'

set kmpkg_commands ($kmpkg_executable autocomplete)

function _set_triplet_arguments
  set triplets ($kmpkg_executable help triplet | grep "^\s" | cut -d' ' -f3)
  set triplet_from ""
  for triplet in $triplets
    echo (test -n "$triplet") >> temp.txt
    if [ (string sub -l5 -- $triplet) = "KMPKG" ]
      set -l temp (string length $triplet)
      set triplet_from (string sub -s6 -l(math $temp - 15) -- $triplet)
    else if [ -n "$triplet" ]
      complete -c kmpkg -n "__fish_seen_subcommand_from $kmpkg_commands" -x -l triplet -d "$triplet_from" -a (string sub -s3 -- $triplet)
    end
  end
end
_set_triplet_arguments

# options for all completions
complete -c kmpkg -n "__fish_seen_subcommand_from $kmpkg_commands" -x -l triplet -d "Specify the target architecture triplet. See 'kmpkg help triplet' (default: \$KMPKG_DEFAULT_TRIPLET)"
complete -c kmpkg -n "__fish_seen_subcommand_from $kmpkg_commands" -x -l overlay-ports -d "Specify directories to be used when searching for ports (also: \$KMPKG_OVERLAY_PORTS)" -a '(__fish_complete_directories)'
complete -c kmpkg -n "__fish_seen_subcommand_from $kmpkg_commands" -x -l overlay-triplets -d "Specify directories containing triplets files (also: \$KMPKG_OVERLAY_TRIPLETS)" -a '(__fish_complete_directories)'
complete -c kmpkg -n "__fish_seen_subcommand_from $kmpkg_commands" -x -l binarysource -d "Add sources for binary caching. See 'kmpkg help binarycaching'" -a '(__fish_complete_directories)'
complete -c kmpkg -n "__fish_seen_subcommand_from $kmpkg_commands" -x -l downloads-root -d "Specify the downloads root directory (default: \$KMPKG_DOWNLOADS)" -a '(__fish_complete_directories)'
complete -c kmpkg -n "__fish_seen_subcommand_from $kmpkg_commands" -x -l kmpkg-root -d "Specify the kmpkg root directory (default: \$KMPKG_ROOT)" -a '(__fish_complete_directories)'

# options for install
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l dry-run -d "Do not actually build or install"
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l head -d "Install the libraries on the command line using the latest upstream sources"
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l no-downloads -d "Do not download new sources"
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l only-downloads -d "Download sources but don't build packages"
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l recurse -d "Allow removal of packages as part of installation"
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l keep-going -d "Continue installing packages on failure"
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l editable -d "Disable source re-extraction and binary caching for libraries on the command line"
complete -c kmpkg -n "__fish_seen_subcommand_from install" -f -l clean-after-build -d "Clean buildtrees, packages and downloads after building each package"

# options for edit
complete -c kmpkg -n "__fish_seen_subcommand_from edit" -f -l buildtrees -d "Open editor into the port-specific buildtree subfolder"
complete -c kmpkg -n "__fish_seen_subcommand_from edit" -f -l all -d "Open editor into the port as well as the port-specific buildtree subfolder"

# options for export
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l dry-run -d "Do not actually export"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l raw -d "Export to an uncompressed directory"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l nuget -d "Export a NuGet package"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l ifw -d "Export to an IFW-based installer"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l zip -d "Export to a zip file"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l 7zip -d "Export to a 7zip (.7z) file"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l prefab -d "Export to Prefab format"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l prefab-maven -d "Enable maven"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -l prefab-debug -d "Enable prefab debug"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l output -d "Specify the output name (used to construct filename)"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l output-dir -d "Specify the output directory for produced artifacts" -a '(__fish_complete_directories)'
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l nuget-id -d "Specify the id for the exported NuGet package (overrides --output)"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l nuget-version -d "Specify the version for the exported NuGet package"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l ifw-repository-url -d "Specify the remote repository URL for the online installer"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l ifw-packages-directory-path -d "Specify the temporary directory path for the repacked packages"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l ifw-repository-directory-path -d "Specify the directory path for the exported repository"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l ifw-configuration-file-path -d "Specify the temporary file path for the installer configuration"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l ifw-installer-file-path -d "Specify the file path for the exported installer"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l prefab-group-id -d "GroupId uniquely identifies your project according maven specifications"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l prefab-artifact-id -d "Artifact Id is the name of the project according maven specifications"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l prefab-version -d "Version is the name of the project according maven specifications"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l prefab-min-sdk -d "Android minimum supported sdk version"
complete -c kmpkg -n "__fish_seen_subcommand_from export" -f -r -l prefab-target-sdk -d "Android target sdk version"

# options for remove
complete -c kmpkg -n "__fish_seen_subcommand_from remove" -f -l purge -d "Remove the cached copy of the package (default)"
complete -c kmpkg -n "__fish_seen_subcommand_from remove" -f -l no-purge -d "Do not remove the cached copy of the package (deprecated)"
complete -c kmpkg -n "__fish_seen_subcommand_from remove" -f -l recurse -d "Allow removal of packages not explicitly specified on the command line"
complete -c kmpkg -n "__fish_seen_subcommand_from remove" -f -l dry-run -d "Print the packages to be removed, but do not remove them"
complete -c kmpkg -n "__fish_seen_subcommand_from remove" -f -l outdated -d "Select all packages with versions that do not match the portfiles"

# options for upgrade
complete -c kmpkg -n "__fish_seen_subcommand_from upgrade" -f -l no-dry-run -d "Actually upgrade"
complete -c kmpkg -n "__fish_seen_subcommand_from upgrade" -f -l keep-going -d "Continue installing packages on failure"
