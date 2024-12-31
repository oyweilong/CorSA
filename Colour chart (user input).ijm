macro "Colour Chart" {
	
//Setting up colour chart ROIs (USER INPUT VERSION)
run("Select None");
for (c=6; c>0; c--) {
		setTool("rectangle");
		waitForUser("Rectangle for C"+c);
		roiManager("Add");
		colourindex=roiManager("size");
		roiManager("select", colourindex-1);
		roiManager("Rename", "Colour "+c);
		
}


colour6ind= findRoiWithName("Colour 6");
roiManager("Select", colour6ind);
roiManager("Measure");
colour6=getResult("Mean");

colour5ind= findRoiWithName("Colour 5");
roiManager("Select", colour5ind);
roiManager("Measure");
colour5=getResult("Mean");

colour4ind= findRoiWithName("Colour 4");
roiManager("Select", colour4ind);
roiManager("Measure");
colour4=getResult("Mean");

colour3ind= findRoiWithName("Colour 3");
roiManager("Select", colour3ind);
roiManager("Measure");
colour3=getResult("Mean");

colour2ind= findRoiWithName("Colour 2");
roiManager("Select", colour2ind);
roiManager("Measure");
colour2=getResult("Mean");

colour1ind= findRoiWithName("Colour 1");
roiManager("Select", colour1ind);
roiManager("Measure");
colour1=getResult("Mean");

//Approximating colour scores to the midway point to the next colour score
col6est=colour6+((colour5-colour6)/2);
col5est=colour5+((colour4-colour5)/2);
col4est=colour4+((colour3-colour4)/2);
col3est=colour3+((colour2-colour3)/2);
col2est=colour2+((colour1-colour2)/2);


//Creating GUI for users to input values for calibration
Dialog.create("Calibration");
Dialog.addMessage("Please indicate the following preferences before batch processing:");

Dialog.addNumber("No. of fragments in image", 0);
Dialog.addNumber("No. of colour references for whole image", 0);

// Finally show the GUI, once all parameters have been added
Dialog.show();

// Once the Dialog is OKed the rest of the code is executed
// ie one can recover the values in order of appearance 
fragno = Dialog.getNumber(); 
colourno = Dialog.getNumber();

print("No. of frags in image:", fragno);
print("No. of colour references:", colourno);

//Setting up ROIs and measuring colour for the number of colour references set by user
run("Select None");
for (colref=0; colref<colourno; colref++){
	setTool("rectangle");
	waitForUser("Rectangle for colour estimate"+(colref+1));
	roiManager("Add");
	colrefindex=roiManager("size");
	roiManager("select", colrefindex-1);
	roiManager("Rename", "Colour Measure "+(colref+1));
	roiManager("Measure");
	colour=getResult("Mean");
	if (colour<col6est)
		colresult=6;
	else if(colour<col5est)
		colresult=5;
	else if(colour<col4est)
		colresult=4;				
	else if(colour<col3est)
		colresult=3;
	else if(colour<col2est)
		colresult=2;
	else if(colour<colour1)
		colresult=1;
	else 
		colresult="Error";
setResult("Colour", nResults-1, colresult);
				
											
}

																			
};

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