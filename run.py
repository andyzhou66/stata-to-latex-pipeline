import sys
import subprocess

def main():
    '''
    Execute the pip-installed scons command.
    Pass on command line arguments from this script's execution.
    '''
    del sys.argv[0]
    cl_args = ' '.join(sys.argv)
    call = 'scons %s' % cl_args
    subprocess.call(call, shell = True)

main()
