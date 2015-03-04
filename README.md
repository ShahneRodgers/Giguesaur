# Info
Set up instructions


# rename origin remote
git remote rename origin github
 
# add the gitlab remote (for the love of everything that’s holy, use ssh)
git remote add bitbucket https://shahnerodgers@bitbucket.org/shahnerodgers/private-work.git
 
# push existing code to new remote
git push -u bitbucket —all
 
# let’s magic
git config -e
 
# add this in the file
[remote “origin”]
url = git@github.com:username/reponame.git
url = https://shahnerodgers@bitbucket.org/shahnerodgers/private-work.git
