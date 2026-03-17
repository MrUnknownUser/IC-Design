# KLayout
## How to manual load .lyp
The *.lyp file for sg13g2 is located in the IHP-GmbH/IHP-Open-PDK repository under ```ihp-sg13g2/libs.tech/klayout/tech/sg13g2.lyp```
Go to ```File -> Load Layer Properties``` and select the *.lyp file 

## How to auto load .lyp
1. Make sure the *.lyp file is in the same directory as the *.gds file
2. Go to ```File -> Setup -> Application -> Layer Properties```
3. Check "Use default layer properties file"
4. Copy the following into the textarea bellow: $(combine(path(layoutfile), basename(layoutfile))+".lyp")
5. Click Ok or Apply button

## How to load .lyrdb
1. Go to ```Tools -> Marker Browser```
2. Find and select the *.lyrdb file
3. KLayout opens a separate Window with all the Marker (who marked Violations) set by Magic DRC or other step in the librelane flow

## No gds produced
If no GDS file is available, there is, for example, a *.mag file in the “view” folder within the Magic DRC Step, which can be converted into a *.gds file that KLayout can read. To convert into a supported formad, such as GDSII, use the Magic VLSI tool (```file -> writeall gds```).