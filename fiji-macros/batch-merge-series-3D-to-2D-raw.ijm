/* =======================================================
Fiji Macro: Batch Merge Series Channels & 3D to 2D images following the below:
- z-index stacked
- No adjustments made to the images and are just raw.
======================================================= */

run("Bio-Formats Macro Extensions");


channelColors = newArray("", "Blue", "Yellow", "Red", "Green");

// 1. Select Input File and Output Folder
file = File.openDialog("Choose the input file (e.g., .nd2, .czi)");
outputDir = getDirectory("Choose Output Directory");

  
// 2. Set Batch Mode for speed
// 20x faster; bypassess overhead of rendering images to the display.
setBatchMode(true); 

// @todo confirm the contrat percentage??
		
soloChannelMerged(1,false,0,0); // #nuclei
soloChannelMerged(2,false,0,0); //myosin
soloChannelMerged(3,false,0,0); // glut4
soloChannelMerged(4,false,0,0); // titin

//glut4 only
//overlayChannelWithNuclei(2,false,0,0);
//overlayChannelWithNuclei(3,false,0,0);
//overlayChannelWithNuclei(4,false,0,0);

// myosin & titin
//overlayChannel2andChannel4WithNuclei();

//overlayOfEachChannelWithNuclei(file);
//overlayChannelWithNuclei(2,false,20,150);
//overlayChannelWithNuclei(4,true,20,150);

//mergeAllChannels(file);

function soloChannelMerged(channel, processImage, min, max){
	// 2. Set Batch Mode for speed
	// 20x faster; bypassess overhead of rendering images to the display.
	setBatchMode(true); 

	Ext.setId(file);
	Ext.getSeriesCount(seriesCount);
	print("Total series found: " + seriesCount);
	
	// 4. Loop through each series
	
	for (s = 1; s <= seriesCount; s++) {
		 showProgress(s, seriesCount);
			    // --- Iterate and Merge Channels for current series ---
			    run("Bio-Formats Importer", "open=[" + file + "] view=Hyperstack stack_order=XYCZT color_mode=Composite series_list=" + (s) + " open_files");
			    
			    // Get image title to handle series
			    imgTitle = getTitle();
			    
			    // 5. Split Channels
			    run("Split Channels");
	
			    // setting channel, its color and stacking the z-indexß 
			    Stack.setChannel(channel);
			    selectImage("C" + channel + "-" +imgTitle);
			    run("Z Project...", "projection=[Max Intensity]"); //3D to 2D (Max Projection) 	    		    
			 	run(channelColors[channel]); 
			    
			    /* Despeckle command to your code to physically remove those single-pixel dots:
			     * Apply LUT after setMinAndMax, you are "baking" the brightness adjustment into the image
			     * so the Merge command is forced to use the cleaned-up version.
			     */
			    if(processImage){
			    	run("Enhance Contrast", "saturated=0.35");   	
			    	run("Despeckle"); // Removes small noise dots
			    	setMinAndMax(min, max);
					run("Apply LUT");
			    }
				rename("ch" + channel + "_2d");
			    
				// Merge Channels works on OPEN IMAGE WINDOWS, not filenames. Therefore, selectImage() the needed one
				run("Merge Channels...", "c" + channel + "=[ch" + channel + "_2d] create");			    
				 // 8. Save and Close
				 saveAs("Tiff", outputDir +"series" + (s) + "_ch"+ channel +"_stacked.tiff");
				 
				 // 2. Get image details to safely process z-stacks/hyperstacks
				getDimensions(width, height, channels, slices, frames);
				
				// 4. Add the Scale Bar
				// Customize width, height, font, and location below
				run("Scale Bar...", "width=20 height=3 font=12 color=White location=[Lower Right] bold overlay");
				saveAs("Png", outputDir +"series" + (s) + "_ch"+ channel +"_stacked.png");
				close("*"); 
	}
	close("*"); // Closes all images
	setBatchMode(false);
	setBatchMode("exit & display"); //to force open all images that were processed.
}


function overlayChannel2andChannel4WithNuclei(processImage=false){
	// 2. Set Batch Mode for speed
	// 20x faster; bypassess overhead of rendering images to the display.
	setBatchMode(true); 

	Ext.setId(file);
	Ext.getSeriesCount(seriesCount);
	print("Total series found: " + seriesCount);
	
	// 4. Loop through each series
	
	for (s = 1; s <= seriesCount; s++) {
		 showProgress(s, seriesCount);
			    // --- Iterate and Merge Channels for current series ---
			    // Example assumes 2 channels, adjust c1, c2 as needed
			    run("Bio-Formats Importer", "open=[" + file + "] view=Hyperstack stack_order=XYCZT color_mode=Composite series_list=" + (s) + " open_files");
			    
			    // Get image title to handle series
			    imgTitle = getTitle();
			    
			    // 5. Split Channels
			    run("Split Channels");
	
			    // Channel 1: DAPI (405nm)
			    Stack.setChannel(1);
			    selectImage("C1-" + imgTitle);
			    run("Z Project...", "projection=[Max Intensity]"); //3D to 2D (Max Projection) 	    		    
			    run("Blue"); 
			    rename("ch1_2d");
			    
			     // Channel 2
			    Stack.setChannel(2);
			    selectImage("C2-" + imgTitle);
			    run("Z Project...", "projection=[Max Intensity]"); //3D to 2D (Max Projection) 	    		    
			    run("Yellow Hot"); // note: no despeckling
				rename("ch2_2d");
				
				 // Channel 4
			    Stack.setChannel(4);
			    selectImage("C4-" + imgTitle);
			    run("Z Project...", "projection=[Max Intensity]"); //3D to 2D (Max Projection) 	    		    
			    run("Cyan"); 
			    rename("ch4_2d");
			    
			    // Function to clean a channel: (ImageName, MinThreshold, MaxBrightness)
				cleanChannel("ch1_2d", 50, 0); // nuclei
				cleanChannel("ch2_2d", 20, 150); // Myosin
				cleanChannel("ch4_2d", 20, 150); // Titin
			    
				// Merge Channels
			    // Merge Channels works on OPEN IMAGE WINDOWS, not filenames. Therefore, selectImage() the needed one
				run("Merge Channels...", "c1=[ch1_2d] c2=[ch2_2d] c4=[ch4_2d] create");
				    
				 // 8. Save and Close
				 saveAs("Tiff", outputDir + File.nameWithoutExtension + "series" + (s) + "_ch2_ch4_with_nuclei_overlay.tiff");
				 
				 //Add the Scale Bar
				 // Customize width, height, font, and location below
				 run("Scale Bar...", "width=20 height=3 font=12 color=White location=[Lower Right] bold overlay");
	}
	close("*"); // Closes all images
	setBatchMode(false);
	setBatchMode("exit & display"); //to force open all images that were processed.
}


function overlayChannelWithNuclei(channel, despeckle, min, max){
	// 2. Set Batch Mode for speed
	// 20x faster; bypassess overhead of rendering images to the display.
	setBatchMode(true); 

	Ext.setId(file);
	Ext.getSeriesCount(seriesCount);
	print("Total series found: " + seriesCount);
	
	// 4. Loop through each series
	
	for (s = 1; s <= seriesCount; s++) {
		 showProgress(s, seriesCount);
			    // --- Iterate and Merge Channels for current series ---
			    // Example assumes 2 channels, adjust c1, c2 as needed
			    run("Bio-Formats Importer", "open=[" + file + "] view=Hyperstack stack_order=XYCZT color_mode=Composite series_list=" + (s) + " open_files");
			    
			    // Get image title to handle series
			    imgTitle = getTitle();
			    
			    // 5. Split Channels
			    run("Split Channels");
	
			    // Channel 1: DAPI (405nm)
			    Stack.setChannel(1);
			    selectImage("C1-" + imgTitle);
			    run("Z Project...", "projection=[Max Intensity]"); //3D to 2D (Max Projection) 	    		    
			    run("Blue"); 
			    if(despeckle){
			    	run("Despeckle"); // Removes small noise dots
			    }
				rename("ch1_2d");
			     
			    Stack.setChannel(channel);
			    selectImage("C"+ channel +"-" + imgTitle);
			    run("Z Project...", "projection=[Max Intensity]"); //3D to 2D (Max Projection) 	    		    
			    run(channelColors[channel]); 
			    if(despeckle){
			    	run("Despeckle"); // Removes small noise dots
			    }
				rename("ch" + channel + "_2d");
			    
			    // Function to clean a channel: (ImageName, MinThreshold, MaxBrightness)
				
			    
				// Merge Channels
			    // Merge Channels works on OPEN IMAGE WINDOWS, not filenames. Therefore, selectImage() the needed one
				run("Merge Channels...", "c1=[ch1_2d] c"+ channel + "=[ch"+ channel + "_2d] create");
				    
				 // 8. Save and Close
				 // use File.nameWithoutExtension if you want the file name
				 saveAs("Tiff", outputDir + "series" + (s) + "_ch"+ channel +"_with_nuclei_overlay.tiff");
				 
				//Add the Scale Bar
				// Customize width, height, font, and location below
				run("Scale Bar...", "width=20 height=3 font=12 color=White location=[Lower Right] bold overlay");
				saveAs("Png", outputDir + "series" + (s) + "_ch"+ channel +"_with_nuclei_overlay.png");
	}
	
	close("*"); // Closes all images
	setBatchMode(false);
	setBatchMode("exit & display"); //to force open all images that were processed.
}


function getMetadataOf(file){
	// Open the .lif file and display ALL metadata in a text window
	run("Bio-Formats", "open=[" + file + "] color_mode=Default display_metadata view=[Metadata only] stack_order=Default");
	
	// To automatically save that metadata window as a text file:
	selectWindow("Original Metadata");
	saveAs("Text", outputDir + "metadata_export.txt");
}


function mergeAllChannels(file){
	Ext.setId(file);
	Ext.getSeriesCount(seriesCount);
	print("Total series found: " + seriesCount);

	// 4. Loop through each series
	for (s = 0; s < seriesCount; s++) {
	    showProgress(s, seriesCount);
	    
	    // --- Iterate and Merge Channels for current series ---
	    // Example assumes 2 channels, adjust c1, c2 as needed
	    run("Bio-Formats Importer", "open=[" + file + "] view=Hyperstack stack_order=XYCZT color_mode=Composite series_list=" + (s+1) + " open_files");
	    
	    // Get image title to handle series
	    imgTitle = getTitle();
	    
	    // 5. Split Channels
	    run("Split Channels");
	
	    // Channel 1: DAPI (405nm)
	    Stack.setChannel(1);
	    selectImage("C1-" + imgTitle);
	    run("Z Project...", "projection=[Max Intensity]"); //3D to 2D (Max Projection) 
	    // Enhance Contrast is a linear adjustment rather than nonlinear adjustments (like Gamma) that drastically distort intensity relationships.
	    run("Enhance Contrast", "saturated=0.35");
	    run("Blue"); 
	    rename("ch1_2d");
	   
	    // Channel 2: Alexa 488 (488nm) - myosin
	    // Myosin signal is naturally punctate (meaning it looks like distinct little dots or "beads on a string" rather than a smooth solid line), therefore, DO NOT use Despeckle
	    Stack.setChannel(2);
	    selectImage("C2-" + imgTitle);
	    run("Z Project...", "projection=[Max Intensity]");
	    run("Enhance Contrast", "saturated=0.35");
	    run("Yellow Hot"); 
	    
	    rename("ch2_2d"); 
	    
	    // Channel 3: mRuby/Glut4 (561nm) nuc
	    Stack.setChannel(3);
	    selectImage("C3-" + imgTitle);
	    run("Z Project...", "projection=[Max Intensity]");
	    run("Enhance Contrast", "saturated=0.35");
	    run("Magenta Hot");
	    run("Despeckle");
	    rename("ch3_2d"); 
	
	 	// Channel 4: Alexa 647 (Normally 640nm) - Titin -located between thick & think filaments 
	    Stack.setChannel(4);
	    selectImage("C4-" + imgTitle);
	    run("Z Project...", "projection=[Max Intensity]");
	    run("Enhance Contrast", "saturated=0.35");
	    run("Despeckle");
	    run("Cyan"); 
	    rename("ch4_2d"); 
	    
		
		// Function to clean a channel: (ImageName, MinThreshold, MaxBrightness)
		cleanChannel("ch1_2d", 50, 0); // nuclei
		cleanChannel("ch2_2d", 20, 150); // Myosin
		cleanChannel("ch3_2d", 15, 120); // glut4
		cleanChannel("ch4_2d", 20, 150); // Titin
		

	    // 7. Merge Channels
	    run("Merge Channels...", "c1=[ch1_2d] c2=[ch2_2d] c3=[ch3_2d] c4=[ch4_2d] create");
	    
	    // 8. Save and Close
	    saveAs("Tiff", outputDir + File.nameWithoutExtension + "_series" + (s+1) + "_all_channels_merged.tif");
	    close("*"); // Closes all images
	}
}

// This function does the heavy lifting
function cleanChannel(name, min, max) {
    if (isOpen(name)) {
        selectWindow(name);
        setMinAndMax(min, max);
        run("Apply LUT"); // This "bakes" the black background into the data
    }
}

setBatchMode(false);
print("Processing Complete.");
setBatchMode("exit & display"); //to force open all images that were processed.
exit();