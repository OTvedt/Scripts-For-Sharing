There are two different scripts for unknow entries in the Azure IAM. 
The newest script can be used for documentation and deleting one and one entry with confirmation. Easier to use when only a few unknows or you just want to check for unknowns without doing changes
Script: Azure-iam-document_and_remove_unknowns.ps1

The second one are more automatic to clean everything without confirmation, it will document what's been deleted, but not ask for confirmation before deleting. Faster way, especial if there are a lot of unknowns
Script: iam-removeunknown.ps1
