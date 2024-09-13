# Quick-Start Guide for Contributing to Exile

## Initial Setup
Fork this repository on Codeberg, using the `fork` button.
Then clone your fork locally:

	$ git clone https://codeberg.org/YOUR_USERNAME/Exile.git --recurse-submodules

Using `cd Exile`, move into the directory, and then `add` my repository as a `remote` codebase:

	$ git remote add -f upstream https://codeberg.org/Mantar/Exile

Having the `upstream` defined is necessary in order to have a fork into which your changes get pulled by the project maintainer.

If you are using Git Bash on windows, be sure to set
        $ checkout.defaultRemote=origin
in your configuration.

## Updating Your Local Copy
Check-out the `branch` labeled `master`, which is where the main `upstream` resides:

	$ git checkout master

Then `pull` from the corresponding `upstream` `branch`:

	$ git pull --ff-only upstream master

This ensures that your local copy of the `repo` correctly reflects the current state of the project maintainer’s copy.

## Making Changes
Create a new `branch` for each `pull request` (`PR`) you plan to make:

	$ git checkout -b BRANCH_NAME

Make your changes and `commit`(s), then `push` them:

	$ git push origin BRANCH_NAME

Now you can go to your fork’s Codeberg page and submit a `PR` to `master`, via the handy web interface.

# Some Simple PR Guidelines
Try to keep your `PR`s focused. Don’t be a politician and bundle your “fund the schools” `PR` together with your “build a bridge to my summer home” `PR`. One `PR` per feature/bugfix, please: No omnibus.

Avoid formatting changes to lines you haven't edited, see style guidelines below.

Try to keep your `commit`s manageably small. The platonic ideal is to have them be atomic, i.e. as small as possible without leaving the code in a broken state. `Git` allows you to find the exact `commit` that introduced a bug, via `git bisect`, which is more useful the smaller that `commit` turns out to be.

That said, don’t worry about it too much, as long as your individual `commit`s aren’t something like seven hundred lines long each, I can probably deal with it.

If you’re not sure about some change or whatever, maybe open a discussion, or file an issue and we can talk it over. Or just make a draft `PR` and we’ll figure it out.

The `v4` branch is where major development is going on right now, with the `master` branch receiving backports and bugfixes.

# Rebasing Stale Branches
“The primary reason for rebasing is to maintain a linear project history.”<sup>[[†]](https://www.atlassian.com/git/tutorials/rewriting-history/git-rebase)</sup>


## Style guidelines
To match our codebase, configure your editor to use 4 spaces for indents

Try to keep lines below 80 columns when possible, and below 120 at the absolute widest.
Narrow lines improve ease of reading, and aid clarity and comprehension. Also, Luacheck will produce warnings for lines wider than 130 columns.

When dealing with large "and/or" blocks, try to break them primarily before an "or", to keep "and" clauses on one line when possible.
Grouping them on separate lines can improve clarity.

If this puts the start of the "and/or" clauses on the same indent level as the code below, insert a line break for separation, or else enclose the block in parentheses and indent them to match.

Please use #TODO for things that need doing later.
