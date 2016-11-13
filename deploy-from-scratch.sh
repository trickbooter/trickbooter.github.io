#!/bin/bash

# publishing branch is master
# site build branch is develop

# Create a new orphand branch (no commit history) named master
git checkout --orphan master

# Unstage all files
git rm --cached $(git ls-files)

# Grab one file from the master branch so we can make a commit
git checkout develop README.md

# Add and commit that file
git add .
git commit -m "INIT: initial commit on master branch"

# Push to remote master branch
git push origin master

# Return to develop branch
git checkout develop

# Remove the public folder to make room for the master subtree
rm -rf public

# Add the master branch of the repository. It will look like a folder named public
git subtree add --prefix=public git@github.com:trickbooter/trickbooter.github.io.git develop --squash

# Pull down the file we just committed. This helps avoid merge conflicts
git subtree pull --prefix=public git@github.com:trickbooter/trickbooter.github.io.git develop

# Run hugo. Generated site will be placed in public directory (or omit -t ThemeName if you're not using a theme)
hugo

# Add everything
git add -A

# Commit and push to master
git commit -m "Updating site" && git push origin develop

# Push the public subtree to the gh-pages branch
git subtree push --prefix=public git@github.com:trickbooter/trickbooter.github.io.git master
