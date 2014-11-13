#
# cleanup.sh
# ==========
# Deletes all compiled CSS, JS, and sourcemap files. Should be run before committing to master.
#

find ./static/js  -name "*.js" -delete
find ./static/js  -name "*.js.map" -delete
find ./static/css -name "*.css" -delete
