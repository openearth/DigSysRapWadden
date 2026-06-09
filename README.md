**Instructions for updating the DSR**

Make sure to follow these steps when making changes or updating information on the DSR:

1. Make sure that the "develop" branch is up to date with "master"
2. Create a new branch from "develop", eg "develop_update_indicator_X"
3. After you are satisfied with the changes, make a pull request from your new branch into "develop". 
   a. Always add a description of the updates in the pull request for documentation purposes
   b. In your pull request, assign a reviewer to make sure the changes are reviewed internally.
   c. Update the review table: P:/11202493--systeemrap-grevelingen/1_data/Wadden/DSR_reviewtabel.csv
   d. Complete the pull request. This triggers the preview workflow. A preview is now generated at https://www.openearth.nl/DigSysRapWadden/preview/develop/ which can be shared with the client for approval
4. After the preview is approved, create a pull request from "develop" to "master".
   a. Doing this, the website automatically gets updated at https://www.systeemrapportage.nl/wadden/
5. Don't forget to delete your new branch "develop_update_indicator_X". NEVER delete "develop", "master" or "gh-pages"

**Checklist after updating the DSR:**

- Did you update the review table? (P:/11202493--systeemrap-grevelingen/1_data/Wadden/DSR_reviewtabel.csv)
- Is 'develop' up to date with 'master'?
- Did you delete the temporary branch you created from develop?

**Explanation of the branches:**

- Master: This branch contains the final code published on the DSR. Executing a pull request to master triggers the workflow updating the DSR: https://www.systeemrapportage.nl/wadden/
- Develop: This branch can be used for testing and review. Executing a pull request to develop triggers the workflow updating the preview website: https://www.openearth.nl/DigSysRapWadden/preview/develop/
- GH - pages: for setup of book with .html files --> do not touch!
