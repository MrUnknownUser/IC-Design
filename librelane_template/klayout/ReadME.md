# KLayout
## How to manual load .lyp
Go to File -> Load Layer Properties and select the *.lyp file 

## How to auto load .lyp
1. Make sure the *.lyp file is in the same directory as the *.gds file
2. Go to File -> Setup -> Application -> Layer Properties
3. Check "Use default layer properties file"
4. Copy the following into the textarea bellow: $(combine(path(layoutfile), basename(layoutfile))+".lyp")
5. Click Ok or Apply button

## How to load .lyrdb
1. Go to Tools -> Marker Browser
2. Find and select the *.lyrdb file
3. KLayout opens a separate Window with all the Marker (who marked Violations) set by Magic DRC or other step in the librelane flow
