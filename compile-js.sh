#
# compile.sh
# ==========
# Compiles all coffeescript files into JS and sourcemap files.
#

coffee -cm ./static/js/*.coffee;
coffee -cm ./static/js/*/*.coffee;
