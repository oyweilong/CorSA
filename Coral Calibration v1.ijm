//Set user parameters
////Creating GUI for users to input values for calibration

Dialog.create("Welcome to the Coral Calibration Macro!");
Dialog.addMessage("Please input the following settings before you begin:");

Dialog.addNumber("No. of fragments in image", 1);

var min = 1;
var max = 7;
var default = 1;
Dialog.addSlider("Minimum SD:", min, max, default);

var min = 0;
var max = 7;
var default = 3;
Dialog.addSlider("Maximum SD:", min, max, default);

Dialog.addSlider("SD increment:", 0.0, 1.0, 0.5);
Dialog.addSlider("No. of manual input reps:", 1, 5, 3);
Dialog.addChoice("Include 'Fill Holes' in analysis?:", newArray("With 'Fill Holes'", "Without 'Fill Holes'", "Both"));
Dialog.addCheckbox("Use 1cm x 1cm square scale?", true);
Dialog.addCheckbox("Use above settings for multiple images?", true);


// Finally show the GUI, once all parameters have been added
Dialog.show();

// Once the Dialog is OKed the rest of the code is executed
// ie one can recover the values in order of appearance 
fragno = Dialog.getNumber();
minsd = Dialog.getNumber();
maxsd = Dialog.getNumber();
increment= Dialog.getNumber();
reps= Dialog.getNumber();
scalecheck = Dialog.getCheckbox();
fillholescheck= Dialog.getChoice();
batchcheck = Dialog.getCheckbox();

path = File.openDialog("Please select the first image you want to process");
open(path);

//Setting up ROIs
roiManager("Reset");

original = getImageID();
for (fragref=0; fragref<fragno; fragref++){
	run("Select None");
	setTool("rectangle");
	waitForUser("Rectangle for frag measure "+(fragref+1));
	roiManager("Add");
	fragindex=roiManager("size");
	roiManager("select", fragindex-1);
	roiManager("Rename", "Frag Measure "+(fragref+1));
}
run("Select None");
for (colref=0; colref<fragno; colref++){
	setTool("rectangle");
	waitForUser("Rectangle for colour estimate "+(colref+1));
	roiManager("Add");
	colrefindex=roiManager("size");
	roiManager("select", colrefindex-1);
	roiManager("Rename", "Colour Measure "+(colref+1));
}


//Loop for processing multiple images
while(batchcheck==true){
	
///////////////////SET SCALE//////////////////////////////////
if (scalecheck==true){
		onecmsquarescale();
}
else{
	//Prompt to manually set scale
	run("Select None");
	run("Set Scale...", "distance=0 known=0 unit=pixel global");
	setTool("line");
	waitForUser("Please manually set your scale");
	setOption("Changes", false);
}

//Manual user input of SA: Prints manual input average and RSD
for (manual=0; manual<fragno; manual++){
	totalarea=0;
	areaarray=newArray();
	sdarray=newArray();
	sdnamearray=newArray();
	diffarray=newArray();
	for (rep=0; rep<reps; rep++){
	selectImage(original);
	run("Select None");
	setTool("polygon");
	setBatchMode(false);
	waitForUser("Please trace out your Frag "+(manual+1)+" (Rep "+(rep+1)+")");
	run("Measure");
	reparea=getResult("Area");
	totalarea=totalarea+reparea;
	Table.deleteRows( nResults-1, nResults-1 );
	areaarray=Array.concat(areaarray,reparea);
	}
	
	//manually calculating standard deviation and RSD without using array.getstatistics
	average=totalarea/reps;
	stdDeviation=0;
	stdarray=Array.copy(areaarray);
	for (i=0; i<stdarray.length; i++){
		stdarray[i]=stdarray[i]-average;
		stdarray[i]=stdarray[i]*stdarray[i];
		stdDeviation=stdDeviation+stdarray[i];
	}
	stdDeviation=stdDeviation/(reps-1);
	stdDeviation=sqrt(stdDeviation);
	rsd=(stdDeviation/average)*100;
	//
	fragmeasure=findRoiWithName("Frag Measure "+(manual+1));
	roiManager("Select", fragmeasure);
	run("Measure");
	setResult("Area",nResults-1,average);
	for(repindex=0; repindex<reps; repindex++){
		i=areaarray[repindex];
		setResult("Rep "+(repindex+1),nResults-1,i);
		updateResults();
	}
	setResult("Manual input RSD (%)",nResults-1,rsd);
	setResult("Closest SD",nResults-1,0);
	setResult("Closest % Similarity",nResults-1,0);
	updateResults();
	
	//Colour threshold section
	colourscore= findRoiWithName("Colour Measure "+(manual+1));
	//Getting colour grey values
	setBatchMode(true);
	selectImage(original);
	run("Duplicate...", "title=RGBstack ignore");
	run("Split Channels");
	selectWindow("RGBstack (red)");
	roiManager("Select", colourscore);
	roiManager("Measure");
	redgrayvalue=getResult("Mean");
	redstddev=getResult("StdDev");
	close();
	
	
	selectWindow("RGBstack (green)");
	roiManager("Select", colourscore);
	roiManager("Measure");
	greengrayvalue=getResult("Mean");
	greenstddev=getResult("StdDev");
	close();
	
	
	selectWindow("RGBstack (blue)");
	roiManager("Select", colourscore);
	roiManager("Measure");
	bluegrayvalue=getResult("Mean");
	bluestddev=getResult("StdDev");
	close();
	
	Table.deleteRows( nResults-3, nResults-1 );
	
	for(sd=minsd; sd<=maxsd; sd+=increment){
		
	redmin=redgrayvalue-redstddev*sd;
	redmax=redgrayvalue+redstddev*sd;
	greenmin=greengrayvalue-greenstddev*sd;
	greenmax=greengrayvalue+greenstddev*sd;
	bluemin=bluegrayvalue-bluestddev*sd;
	bluemax=bluegrayvalue+bluestddev*sd;
	
	//Colour threshold mask
	selectImage(original);
	run("Select None");
	run("Duplicate...", "title=ColourThresholdMask");
	selectImage("ColourThresholdMask");
	
	// Colour Thresholding-------------
	// Color Thresholder 2 .3.0/1.53s
	// Autogenerated macro, single images only!
	min=newArray(3);
	max=newArray(3);
	filter=newArray(3);
	a=getTitle();
	run("RGB Stack");
	run("Convert Stack to Images");
	selectWindow("Red");
	rename("0");
	selectWindow("Green");
	rename("1");
	selectWindow("Blue");
	rename("2");
	
	min[0]=redmin;
	max[0]=redmax;
	filter[0]="pass";
	min[1]=greenmin;
	max[1]=greenmax;
	filter[1]="pass";
	min[2]=bluemin;
	max[2]=bluemax;
	filter[2]="pass";
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  setThreshold(min[i], max[i]);
	  run("Convert to Mask");
	  if (filter[i]=="stop")  run("Invert");
	}
	imageCalculator("AND create", "0","1");
	imageCalculator("AND create", "Result of 0","2");
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  close();
	}
	selectWindow("Result of 0");
	close();
	selectWindow("Result of Result of 0");
	rename(a);
	// Colour Thresholding-------------
	
	// Convert to Mask and get surface area of frag
	if (fillholescheck=="With 'Fill Holes'"){
	run("Convert to Mask");
	run("Fill Holes");
	fragm=findRoiWithName("Frag Measure "+(manual+1));
	roiManager("Select", fragm);
	run("Analyze Particles...", "size=0.1-Infinity display");
	sdresult=getResult("Area");
	sdsim=(sdresult/average)*100;
	Table.deleteRows( nResults-1, nResults-1 );
	setResult("SD "+sd+" with 'Fill Holes'",nResults-1,sdresult);
	setResult("SD "+sd+"(% similarity)", nResults-1, sdsim);
	updateResults();
	sdname="SD "+sd+" with 'Fill Holes'";
	sdarray=Array.concat(sdarray,sdresult);
	sdnamearray=Array.concat(sdnamearray,sdname);
	closestsd=999;
	for(i=0; i<sdarray.length; i++){
		diff=(abs(sdarray[i]-average)/average)*100;
		diffarray[i]=diff;
		if (diffarray[i]<closestsd){
			closestsd=diffarray[i];
			sdnameindex=i;
		}
	}
	chosen=sdnamearray[sdnameindex];
	chosensim=sdarray[sdnameindex];
	chosensim=(chosensim/average)*100;
	setResult("Closest SD", nResults-1,chosen);
	setResult("Closest % Similarity",nResults-1,chosensim);
	updateResults();
	close();	
	}
	
	else if (fillholescheck=="Without 'Fill Holes'"){
	run("Convert to Mask");
	fragm=findRoiWithName("Frag Measure "+(manual+1));
	roiManager("Select", fragm);
	run("Analyze Particles...", "size=0.1-Infinity display");
	sdresult=getResult("Area");
	sdsim=(sdresult/average)*100;
	Table.deleteRows( nResults-1, nResults-1 );
	setResult("SD "+sd,nResults-1,sdresult);
	setResult("SD "+sd+"(% similarity)", nResults-1, sdsim);
	updateResults();
	sdname="SD "+sd;
	sdarray=Array.concat(sdarray,sdresult);
	sdnamearray=Array.concat(sdnamearray,sdname);
	closestsd=999;
	for(i=0; i<sdarray.length; i++){
		diff=(abs(sdarray[i]-average)/average)*100;
		diffarray[i]=diff;
		if (diffarray[i]<closestsd){
			closestsd=diffarray[i];
			sdnameindex=i;
		}
	}
	chosen=sdnamearray[sdnameindex];
	chosensim=sdarray[sdnameindex];
	chosensim=(chosensim/average)*100;
	setResult("Closest SD", nResults-1,chosen);
	setResult("Closest % Similarity",nResults-1,chosensim);
	updateResults();
	close();
	}
	
	
	else if (fillholescheck=="Both"){
	run("Convert to Mask");
	fragm=findRoiWithName("Frag Measure "+(manual+1));
	roiManager("Select", fragm);
	run("Analyze Particles...", "size=0.1-Infinity display");
	sdresult=getResult("Area");
	sdsim=(sdresult/average)*100;
	Table.deleteRows( nResults-1, nResults-1 );
	setResult("SD "+sd,nResults-1,sdresult);
	setResult("SD "+sd+"(% similarity)", nResults-1, sdsim);
	updateResults();
	sdname="SD "+sd;
	sdarray=Array.concat(sdarray,sdresult);
	sdnamearray=Array.concat(sdnamearray,sdname);
	
	run("Fill Holes");
	fragm=findRoiWithName("Frag Measure "+(manual+1));
	roiManager("Select", fragm);
	run("Analyze Particles...", "size=0.1-Infinity display");
	sdresult2=getResult("Area");
	sdsim2=(sdresult2/average)*100;
	Table.deleteRows( nResults-1, nResults-1 );
	setResult("SD "+sd+" With 'Fill Holes'",nResults-1,sdresult2);
	setResult("SD "+sd+" With 'Fill Holes'"+"(% similarity)", nResults-1, sdsim2);
	updateResults();
	sdname2="SD "+sd+" With 'Fill Holes'";
	sdarray=Array.concat(sdarray,sdresult2);
	sdnamearray=Array.concat(sdnamearray,sdname2);
	closestsd=999;
	for(i=0; i<sdarray.length; i++){
		diff=(abs(sdarray[i]-average)/average)*100;
		diffarray[i]=diff;
		if (diffarray[i]<closestsd){
			closestsd=diffarray[i];
			sdnameindex=i;
		}
	}
	chosen=sdnamearray[sdnameindex];
	chosensim=sdarray[sdnameindex];
	chosensim=(chosensim/average)*100;
	setResult("Closest SD", nResults-1,chosen);
	setResult("Closest % Similarity",nResults-1,chosensim);
	updateResults();
	close();	
	}
	}

}

continuecheck=getBoolean("Would you like to calibrate the next image?");
if (continuecheck==false){
	batchcheck=false;
	//Delete off unnecessary tables
	Table.deleteColumn("Mean");
	Table.deleteColumn("StdDev");
	Table.deleteColumn("Min");
	Table.deleteColumn("Max");
	Table.deleteColumn("MinThr");
	Table.deleteColumn("MaxThr");
	updateResults();
	
}
else{
	run("Open Next");
	setBatchMode(false);	
}
}//end of batch loop

//Export data to new Excel file/add to existing Excel file
export=getBoolean("Would you like to export your results to an Excel file?");
if (export==true){
	Dialog.create("Export to Excel file");
	Dialog.addHelp("https://imagej.net/plugins/read-and-write-excel#usage");
	items = newArray("Add to existing Excel file", "Create new Excel file");
  	Dialog.addRadioButtonGroup(" ", items, 1, 2, "Add to existing Excel file");
  	Dialog.addMessage("Note: The Read and Write Excel plugin is required, click Help for an installation guide");
	Dialog.show();
	addorcreate=Dialog.getRadioButton();
	
	//Add to existing Excel file
	if (addorcreate=="Add to existing Excel file"){
	Dialog.create("Add to existing Excel file");	
	Dialog.addFile("Excel file path:", "Enter your Excel file path here");
	Dialog.addString("Sheet Name:", "Sheet1",31);
	Dialog.addString("Data label:", " ");
	Dialog.addCheckbox("Include Count number?", false);
	items= newArray("Adjacent to existing data", "Under existing data");
	Dialog.addRadioButtonGroup("Where do you want to append your data?", items, 1, 2, "Adjacent to existing data");	
	Dialog.addMessage("Warning: Ensure that the Excel file you selected above is not open before proceeding!");
	Dialog.show();
	excelfilepath=Dialog.getString();
	sheetpath=Dialog.getString();
	datalabel=Dialog.getString();
	countnumber=Dialog.getCheckbox();
	stackornot=Dialog.getRadioButton();
	//Replacing \ with / to fit Read and Write excel syntax
	correctedexcel=replace(excelfilepath,"\\", "/");
	//fitting user inputs into Read and Write excel syntax
	ReadandWriteExcelsyntax="file=["+correctedexcel+"] "+"sheet="+sheetpath+" dataset_label=["+datalabel+"]";
	if (countnumber==false){
		ReadandWriteExcelsyntax=ReadandWriteExcelsyntax+" no_count_column";
	}
	if (stackornot=="Under existing data"){
		ReadandWriteExcelsyntax=ReadandWriteExcelsyntax+" stack_results";
	}
	run("Read and Write Excel", ReadandWriteExcelsyntax);
	Dialog.create(" ");
	Dialog.addMessage("Your calibration is complete, thank you for using this macro!");
	Dialog.show();
	}
	
	//Create a new Excel file
	else{
	Dialog.create("Create a new Excel file");	
	Dialog.addDirectory("New Excel file directory:", "Enter the directory for your new Excel file here");
	Dialog.addString("New Excel file name:", "Coral surface area and colour data",48);
	Dialog.addString("Sheet Name:", "Sheet1",48);
	Dialog.addString("Data label:", " ");
	Dialog.addCheckbox("Include Count number?", false);	
	Dialog.show();
	excelfiledir=Dialog.getString();
	excelfilename=Dialog.getString();
	sheetpath=Dialog.getString();
	datalabel=Dialog.getString();
	countnumber=Dialog.getCheckbox();
	excelfilepath=excelfiledir+excelfilename+".xlsx";
	//Replacing \ with / to fit Read and Write excel syntax
	correctedexcel=replace(excelfilepath,"\\", "/");
	//fitting user inputs into Read and Write excel syntax
	ReadandWriteExcelsyntax="file=["+correctedexcel+"] "+"sheet="+sheetpath+" dataset_label=["+datalabel+"]";
	if (countnumber==false){
		ReadandWriteExcelsyntax=ReadandWriteExcelsyntax+" no_count_column";
	}
	
	run("Read and Write Excel", ReadandWriteExcelsyntax);
	Dialog.create(" ");
	Dialog.addMessage("Your calibration is complete, thank you for using this macro!");
	Dialog.show();
	}	
}


else{
	Dialog.create(" ");
	Dialog.addMessage("Your calibration is complete, thank you for using this macro! Please refer to the Results table for the results.");
	Dialog.show();
}
//







//Function for setting scale using a black 1x1cm square as reference (with user input for ROI prompt)
function onecmsquarescale(){
		//Clear any existing scale
		run("Select None");
		run("Set Scale...", "distance=0 known=0 unit=pixel global");
		//Setting up ROI for 1cm x 1cm square
		setTool("rectangle");
		waitForUser("Please select your 1cm x 1cm square");
		roiManager("Add");
		scaleindex=roiManager("size");
		roiManager("select", scaleindex-1);
		roiManager("Rename", "1cm x 1cm square");		
		//Create mask from 8bit image and measure area of 1cmx1cm square
		setBatchMode(true);
		original = getImageID();
		selectImage(original);
		setOption("Changes", false);
		run("Duplicate...", "title=8bitmask ignore");
		selectImage("8bitmask");
		run("8-bit");
		run("Convert to Mask");
		run("Set Measurements...", "area mean standard min limit display redirect=None decimal=3");
		squarescale= findRoiWithName("1cm x 1cm square");
		roiManager("select", squarescale);
		run("Measure");
		selectImage("8bitmask");
		close();
		//Area of the 1cmx1cm square converted into 1cm distance in pixels
		blacksquarearea=getResult("Area");
		onecmdistance=sqrt(blacksquarearea);
		//Setting scale with 1cm distance in pixels
		selectImage(original);
		run("Set Scale...", "distance=onecmdistance known=1 unit=cm global");
		Table.deleteRows( nResults-1, nResults-1 );
		setOption("Changes", false);
		setBatchMode(false);	
}

//Function for looking up Roi by name and returning its index number (RoiManager.selectByName(name) for newer imageJ versions)
function findRoiWithName(roiName) { 
	nR = roiManager("Count"); 
 
	for (i=0; i<nR; i++) { 
		roiManager("Select", i); 
		rName = Roi.getName(); 
		if (matches(rName, roiName)) { 
			return i; 
		} 
	} 
	return -1; 
} 
