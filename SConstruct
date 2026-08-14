# Preliminaries
import os
import sys
import atexit
import yaml
import shutil
import subprocess

sys.path.append('config')
sys.dont_write_bytecode = True  # Don't write .pyc files

# Ensure config_user.yaml exists
if not os.path.isfile('config_user.yaml'):
    if os.path.isfile('config_user_template.yaml'):
        shutil.copy('config_user_template.yaml', 'config_user.yaml')
    elif os.path.isfile('config/config_user_template.yaml'):
        shutil.copy('config/config_user_template.yaml', 'config_user.yaml')

# Setup
from configuration import configuration
[mode, cache_dir, CONFIG, executable_names, prereqs, pythonpath] = configuration(ARGUMENTS)
import gslab_scons as gs

# --------------------------------------------------------------------------
# Custom multi-pass PDF builder.
# BuildLatex runs pdflatex ONCE. The guidelines document has a table of
# contents, list of tables, PDF bookmarks, and \ref cross-references, all of
# which need >=2 passes (bookmarks need 3). build_pdf() delegates to
# 3.build-paper/code/build_pdf.py, which loops pdflatex until the .aux is
# stable (max 3 passes) from the pipeline root with forward-slash paths.
# --------------------------------------------------------------------------
def build_pdf(target, source, env):
    tex = str(source[0]).replace('\\', '/')
    pdf = str(target[0]).replace('\\', '/')
    cmd = '"%s" "3.build-paper/code/build_pdf.py" "%s" "%s"' % (sys.executable, tex, pdf)
    return subprocess.call(cmd, shell = True)

# Define the SCons environment
env = Environment(ENV = {'PATH': os.environ['PATH'], 'PYTHONPATH': pythonpath},
                  IMPLICIT_COMMAND_DEPENDENCIES = 0,
                  BUILDERS = {
                              'BuildStata' : Builder(action = gs.build_stata),
                              'BuildLatex' : Builder(action = gs.build_latex),
                              'BuildPdf'   : Builder(action = build_pdf),
                              })
# Load environment variables from configuration
env['CONFIG'] = CONFIG
env['executable_names'] = executable_names
# Only computes hash if time-stamp changed
env.Decider('MD5-timestamp')
# Export environment
Export('env')
# Additional mode options
if mode == 'cache':
    CacheDir(cache_dir)

# Logging (except on dry run)
gs.log.start_log(mode, cl_args_list = sys.argv)
atexit.register(gs.log.end_log)
gs.log_paths_dict(CONFIG)
debrief_args = CONFIG['global']['scons_debrief_args']
debrief_args['lfs_required'] = bool('git_lfs' in prereqs)
atexit.register(gs.scons_debrief, args = debrief_args)

# Run sub-trees (3 numbered steps: data -> tables -> paper)
SConscript('1.prepare-data/SConscript')
SConscript('2.generate-tables/SConscript')
SConscript('3.build-paper/SConscript')

Default('#release')
