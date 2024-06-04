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
# default Windows venv does not have an activate.fish script
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

## AutoVenv Function
# Activates on directory changes.
function autovenv --on-variable PWD -d "Automatic activation of Python virtual environments"
    # Check for the enable flag and make sure we're running interactive, if not return.
    test ! "$autovenv_enable" = "yes"
        or not status is-interactive
        and return
    # Start at PWD (prsent working directory, see if there is a subfolder that contains bin/activate
    # ie. start at $PWD/<subdir from autovenv_dirs>/bin/activate
    # If that doesn't exist, try $PWD/../<subdir from autovenv_dirs>/bin/activate
    # Keep going until we cannot go any further
    set -l _tree "$PWD/."
    set -l _done false
    while true
        set -l _tree_old "$_tree"
        set _tree (path dirname -- "$_tree")
        if test -z "$_tree" -o "$_tree" = "$_tree_old"
            # dirname of / is /, so we've reached the end
            break
        end

        set -l _possible_dirs

        # check autovenv_file presence
        if test -f "$_tree/$autovenv_file"
            set -l _venv_dir_from_file (cat "$_tree/$autovenv_file" | string trim)
            if test -n "$_venv_dir_from_file" -a -d "$_venv_dir_from_file"
                # add directory from autovenv_file to possible directories
                set -a _possible_dirs "$_venv_dir_from_file"
            end
        end

        # check directory from autovenv_dirs presence
        for _venv_dir in (path filter -d -- "$_tree"/*)
            set -l _venv_dir_basename (path basename -- "$_venv_dir")
            for _dir in $autovenv_dirs
                if string match -q -- "$_dir" "$_venv_dir_basename"
                    set -a _possible_dirs "$_venv_dir"
                end
            end
        end

        for _dir in $_possible_dirs
            # found a match, check for the presence of the activate script
            if test -e "$_dir/bin/activate" -o -e "$_dir/Scripts/activate"
                set _source "$_dir"
                if test "$autovenv_announce" = "yes"
                    set -g __autovenv_old $__autovenv_new
                    set -g __autovenv_new (path basename -- "$_dir")
                    set venv_dir $_dir
                end
                set _done true
                break
            end
        end

        if $_done
            break
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
        set _dir (string match -n "$VIRTUAL_ENV*" "$venv_dir")
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
    set -l _dirs (path filter -d -- "$autovenv_envs"/*)
    for _venv in $_dirs
        echo (path basename -- "$_venv")
    end
end

function venvmk -d "Create a new external virtual environment"
    argparse 'p/python=' -- $argv
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

    if test -d "$autovenv_file"
        echo "Cannot create $autovenv_file file in current directory."
        return
    end

    $_flag_python -m venv "$_venv_dir"
    if test $status -ne 0
        echo "Failed to create virtual environment."
        return
    end

    echo "$_venv_dir" > "$autovenv_file"
    echo "Virtual environment created."
end

function venvrm -d "Remove an external virtual environment"
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
