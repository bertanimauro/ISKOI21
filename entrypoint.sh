#!/bin/bash
set -e

echo "Starting the Jekyll Action"

echo "::debug ::Starting bundle install"
bundle install
echo "::debug ::Completed bundle install"

if [[ ${INPUT_JEKYLL_SRC} ]]; then
  JEKYLL_SRC=${INPUT_JEKYLL_SRC}
  echo "::debug ::Using parameter value ${INPUT_JEKYLL_SRC} as a source directory"
elif [[ ${SRC} ]]; then
  JEKYLL_SRC=${SRC}
  echo "::debug ::Using SRC environment var value ${INPUT_JEKYLL_SRC} as a source directory"
else
  JEKYLL_SRC=$(find . -name _config.yml -exec dirname {} \;)
  echo "::debug ::Resolved ${INPUT_JEKYLL_SRC} as a source directory"
fi

bundle exec jekyll build -s ${JEKYLL_SRC} -d build
echo "Jekyll build done"


# No need to have GitHub Pages to run Jekyll
touch .nojekyll

# Is this a regular repo or an org.github.io type of repo
if [[ "${GITHUB_REPOSITORY}" == *".github.io"* ]]; then
  remote_branch="master"
else
  remote_branch="gh-pages"
fi

if [ "${GITHUB_REF}" == "refs/heads/${remote_branch}" ]; then
  echo "Cannot publish on branch ${remote_branch}"
  exit 1
fi

echo "Publishing to ${GITHUB_REPOSITORY} on branch ${remote_branch}"

remote_repo="https://${JEKYLL_PAT}@github.com/${GITHUB_REPOSITORY}.git" && \
git init && \
git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
git add . && \
git commit -m 'jekyll build from Action' && \
git push --force $remote_repo master:$remote_branch && \
rm -fr .git && \
cd ..
exit 0
