################################################################################
############  AutoVenv for Fish Shell v2019.03.28 by @TimothyBrown  ############
################################################################################
## AutoVenv Settings
if status is-interactive
    test -z "$autovenv_announce"
        and set -g autovenv_announce "yes"
    test -z "$autovenv_enable"
        and set -g autovenv_enable "yes"
    test -z "$autovenv_dirs"
        and set -g autovenv_dirs "venv" ".venv" "env" ".env"
    test -z "$autovenv_file"
        and set -g autovenv_file ".venv"
    test -z "$autovenv_envs"
        and set -g autovenv_envs "$HOME/.virtualenvs"
end

# Default activate.fish script with minor modifications
# required, as default Windows venv does not have an activate.fish script
function activate -d "Activate a Python virtual environment"
    function deactivate -d "Exit virtual environment and return to normal shell environment"
        # reset old environment variables
        if test -n "$_OLD_VIRTUAL_PATH"
            set -gx PATH $_OLD_VIRTUAL_PATH
            set -e _OLD_VIRTUAL_PATH
        end
        if test -n "$_OLD_VIRTUAL_PYTHONHOME"
            set -gx PYTHONHOME $_OLD_VIRTUAL_PYTHONHOME
            set -e _OLD_VIRTUAL_PYTHONHOME
        end

        if test -n "$_OLD_FISH_PROMPT_OVERRIDE"
            set -e _OLD_FISH_PROMPT_OVERRIDE
            # prevents error when using nested fish instances (Issue #93858)
            if functions -q _old_fish_prompt
                functions -e fish_prompt
                functions -c _old_fish_prompt fish_prompt
                functions -e _old_fish_prompt
            end
        end

        set -e VIRTUAL_ENV
        set -e VIRTUAL_ENV_PROMPT
        if test "$argv[1]" != "nondestructive"
            # Self-destruct!
            functions -e deactivate
        end
    end

    # Unset irrelevant variables.
    deactivate nondestructive

    set -gx VIRTUAL_ENV "$argv[1]"

    set -gx _OLD_VIRTUAL_PATH $PATH

    if test -e "$VIRTUAL_ENV/bin"
        set -gx PATH "$VIRTUAL_ENV/bin" $PATH
    else if test -e "$VIRTUAL_ENV/Scripts"
        set -gx PATH "$VIRTUAL_ENV/Scripts" $PATH
    end

    # Unset PYTHONHOME if set.
    if set -q PYTHONHOME
        set -gx _OLD_VIRTUAL_PYTHONHOME $PYTHONHOME
        set -e PYTHONHOME
    end

    if test -z "$VIRTUAL_ENV_DISABLE_PROMPT"
        # fish uses a function instead of an env var to generate the prompt.

        # Save the current fish_prompt function as the function _old_fish_prompt.
        functions -c fish_prompt _old_fish_prompt

        # With the original prompt function renamed, we can override with our own.
        function fish_prompt
            # Save the return status of the last command.
            set -l old_status $status

            # Output the venv prompt; color taken from the blue of the Python logo.
            printf "%s%s%s" (set_color 4B8BBE) "(venv) " (set_color normal)

            # Restore the return status of the previous command.
            echo "exit $old_status" | .
            # Output the original/"old" prompt.
            _old_fish_prompt
        end

        set -gx _OLD_FISH_PROMPT_OVERRIDE "$VIRTUAL_ENV"
        set -gx VIRTUAL_ENV_PROMPT "(venv) "
    end
end

# Gets particular elements from an array
# eg. $some_array | select 1 3
# Returns the first and 3rd elements
function select
  read --local --array --null arr
  echo $arr[$argv]
end

function __is_subdirectory --description "Check if one directory is parent of another (after link resolution)"
    set -l parent (realpath "$argv[1]")
    set -l child (realpath "$argv[2]")
    string match -q -- "$parent/*" "$child"
end

function __is_valid_venv_directory --description "Check if the directory is a valid virtual environment"
    set -l venv_dir $argv[1]
    test -d "$venv_dir" -a -e "$venv_dir/bin/activate" -o -e "$_venv_dir/Scripts/activate"
end

function __check_venv_directory --description "Check if the directory has a virtual environment"
    set -l directory $argv[1]

    # is autovenv_file presence
    if test -f "$directory/$autovenv_file"
        set -l venv_dir (cat "$_tree/$autovenv_file" | string trim)
        # is directory from file valid
        if test -n "$venv_dir" -a -d "$venv_dir"
            if __is_subdirectory "$autovenv_envs" "$venv_dir"
                if __is_valid_venv_directory "$venv_dir"
                    echo "$venv_dir"
                    return
                end
            end
        end
    end

    # is directory from autovenv_dirs presence
    for subdirectory in $autovenv_dirs
        set -l venv_dir "$directory/$subdirectory"
        # skip if subdirectory is not present
        if not test -d "$venv_dir"
            continue
        end
        if not __is_subdirectory "$directory" "$venv_dir"
            continue
        end
        if __is_valid_venv_directory "$venv_dir"
            echo "$venv_dir"
            return
        end
    end
end

# Function to find venv specific directory
function __detect_venv_directory --description "Detects the virtual environment directory"
    set -l initial_dir $argv[1]
    set -l dir "$initial_dir/."

    while true
        set -l prev_dir "$dir"
        set -l dir (path dirname -- "$dir")
        if test -z "$dir" -o "$dir" = "$prev_dir"
            break
        end
        set -l venv_dir (__check_venv_directory "$dir")
        if test -n "$venv_dir"
            echo "$venv_dir"
            return
        end
    end
end


## AutoVenv Function
# Activates on directory changes.
function autovenv --on-variable PWD -d "Automatic activation of Python virtual environments"
    # Check for the enable flag and make sure we're running interactive, if not return.
    test ! "$autovenv_enable" = "yes"
        or not status is-interactive
        and return

    set -l found_dir (__detect_venv_directory "$PWD")
    if test -n "$found_dir"
        set _source "$found_dir"
        if test "$autovenv_announce" = "yes"
            set -g __autovenv_old $__autovenv_new
            set -g __autovenv_new (path basename -- "$found_dir")
            set -l venv_dir "$found_dir"
        end
    end

    # If we're *not* in an active venv and the venv source dir exists we activate it and return.
    if test -z "$VIRTUAL_ENV" -a -e "$_source"
        activate "$_source"
        if test "$autovenv_announce" = "yes"
            echo "Activated Virtual Environment ($__autovenv_new)"
        end
    # Next we check to see if we're already in an active venv. If so we proceed with further tests.
    else if test -n "$VIRTUAL_ENV"
        # Check to see if our CWD is inside the venv directory.
        set -l _dir (string match -n "$VIRTUAL_ENV*" "$venv_dir")
        # If we're no longer inside the venv dirctory deactivate it and return.
        if test -z "$_dir" -a ! -e "$_source"
            deactivate
            if test "$autovenv_announce" = "yes"
                echo "Deactivated Virtual Enviroment ($__autovenv_new)"
                set -e __autovenv_new
                set -e __autovenv_old
            end
        # If we've switched into a different venv directory, deactivate the old and activate the new.
        else if test -z "$_dir" -a -e "$_source"
            deactivate
            activate "$_source"
            if test "$autovenv_announce" = "yes"
                echo "Switched Virtual Environments ($__autovenv_old => $__autovenv_new)"
            end
        end
    end
end
################################################################################

## Extra functions for external venv management

function venvls -d "List external virtual environments"
    if contains -- '-h' $argv
        echo "Usage: venvls"
        echo "List external virtual environments."
        return
    end
    set -l _dirs (path filter -d -- "$autovenv_envs"/*)
    for _venv in $_dirs
        echo (path basename -- "$_venv")
    end
end

function venva -d "Activate an external virtual environment"
    if contains -- '-h' $argv
        echo "Usage: venva [name]"
        echo "Activate an external virtual environment."
        echo "If explicit name is not provided, $autovenv_file file or current directory name is used."
        return
    end

    set -l name "$argv[1]"
    set -l directory (path dirname -- "$PWD")

    set -f venv_dir

    if test -n "$name"
        set -l test_dir (path normalize "$autovenv_envs/$name")
        if ! __is_valid_venv_directory "$test_dir"
            echo "Virtual environment does not exist."
            return
        end
        set -f venv_dir "$test_dir"
    end

    if test -z "$venv_dir"
        set -f venv_dir (__detect_venv_directory "$PWD")
    end

    if test -z "$venv_dir"
        set -l test_dir (path normalize "$autovenv_envs/$directory")
        if __is_valid_venv_directory "$test_dir"
            set -f venv_dir "$test_dir"
        end
    end

    if test -z "$venv_dir"
        echo "Virtual environment not found."
        return
    end

    activate "$venv_dir"
    echo "Virtual environment activated."
end

function venvmk -d "Create a new external virtual environment"
    if contains -- '-h' $argv
        echo "Usage: venvmk [-p python] [-m] [name]"
        echo "Create a new external virtual environment."
        echo "If no name is provided, the current directory name is used."
        echo "  -p python: Specify the Python interpreter to use."
        echo "  -m: Manual mode, do not create $autovenv_file file."
        return
    end
    argparse 'p/python=' 'm/manual' -- $argv
    if test $status -ne 0
        return
    end

    if test -z "$_flag_python"
        set -l _default_pythons "python3" "py"
        for _python in $_default_pythons
            if type -q "$_python"
                set _flag_python $_python
                break
            end
        end
        if test -z "$_flag_python"
            echo "Python not found."
            return
        end
    end

    set -l _name
    if test -z "$argv"
        set _name (path basename -- "$PWD")
    else
        set _name "$argv[1]"
    end

    set -l _venv_dir "$autovenv_envs/$_name"
    if test -d "$_venv_dir"
        echo "Virtual environment already exists."
        return
    end

    if test -z "$_flag_manual" -a -d "$autovenv_file"
        echo "Cannot create $autovenv_file file in current directory."
        return
    end

    $_flag_python -m venv "$_venv_dir"
    if test $status -ne 0
        echo "Failed to create virtual environment."
        return
    end

    if test -z "$_flag_manual"
        echo "$_venv_dir" > "$autovenv_file"
    end
    echo "Virtual environment created."
end

function venvrm -d "Remove an external virtual environment"
    if contains -- '-h' $argv
        echo "Usage: venvrm [name]"
        echo "Remove an external virtual environment."
        echo "If no name is provided, the current directory name is used."
        return
    end
    set -l _name
    if test -z "$argv"
        set _name (path basename -- "$PWD")
    else
        set _name "$argv[1]"
    end

    set -l _venv_dir (path normalize "$autovenv_envs/$_name")
    # Normalized path must be inside the autovenv_envs directory
    # to prevent accidental deletion of random things
    set -l _match (string match -- "$autovenv_envs/*" "$_venv_dir")
    if test ! "$_match"
        echo "Invalid virtual environment."
        return
    end

    if ! test -d "$_venv_dir"
        echo "Virtual environment does not exist."
        return
    end

    rm -rf "$_venv_dir"
    echo "Virtual environment removed."
end
