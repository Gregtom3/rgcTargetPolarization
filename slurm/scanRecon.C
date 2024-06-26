// scanRecon
// Purpose: Parse through HEL::scaler and RUN::scaler for each run and save information to csv's
// To execute properly, simply perform ./run.sh
#include <filesystem>
namespace fs = std::filesystem;

int scanRecon(int run = 16137,
	      std::string prefix = "/farm_out/gmat/rgc-scaler-run",
	      std::string header="/cache/clas12/rg-c/production/summer22/pass1/10.5gev/NH3/dst"){
  // Verbosity
  int verbosity = 0;
  
  // Filenames
  std::string fileprefix_recon = Form("%s/recon/0%d/",header.c_str(),run);
  std::string outHELScaler = Form("%s-%d-HELScaler.csv",prefix.c_str(),run);
  std::string outRUNScaler = Form("%s-%d-RUNScaler.csv",prefix.c_str(),run);
   
  // 5 number 
  size_t maxZeros = 5;

  // HEL::Scaler bank info
  double HEL_fcupgated = 0.0;
  double HEL_fcup = 0.0;
  double HEL_slmgated = 0.0;
  double HEL_slm = 0.0;
  double HEL_clockgated = 0.0;
  double HEL_clock = 0.0;
  int HEL_helicity = 0;
  int HEL_helicityRaw = 0;

  // RUN::Scaler bank info
  double RUN_fcupgated = 0.0;
  double RUN_fcup = 0.0;
  double RUN_livetime = 0.0;
  
  // RAW::Scaler bank info
  double offset = 140.0;
  double slope = 906.2;
  double atten = 1.0;
  long RAW_fcupgated_33ms = 0.0;
  long RAW_fcupgated_500us = 0.0;
  long RAW_clockgated_33ms = 0.0;
  long RAW_clockgated_500us = 0.0;
  int  RAW_channel = 0;
  int  RAW_slot = 0;

  ofstream outFile_HEL(outHELScaler,fstream::trunc);
  ofstream outFile_RUN(outRUNScaler,fstream::trunc);


  std::string filename = "";
  std::string filesuffix = "";

  hipo::reader     reader_;
  hipo::event      event_;
  hipo::dictionary  factory_;
  
  outFile_HEL << "run , idx_file , entry_idx , HEL_tot_fcupgated , HEL_tot_fcupgated_pos , HEL_tot_fcupgated_neg , HEL_tot_fcupgated_zero , RAW_tot_fcupgated , RAW_tot_fcupgated_pos , RAW_tot_fcupgated_neg , RAW_tot_fcupgated_zero \n";
  
  outFile_RUN << "run , idx_file , entry_idx , RUN_fcupgated_min , RUN_fcupgated_max , RUN_fcupgated_diff , RUN_tot_livetime , RUN_tot_livetime_per_entry_idx , RUN_fcup_min , RUN_fcup_max , RUN_fcup_diff , RUN_calc_fcupgated \n";

  int idx_file = 0;
  for (const auto& entry : fs::directory_iterator(fileprefix_recon.c_str())) {
    cout << "Run " << run << "| File Number " << idx_file++ << endl;
    if (!entry.is_regular_file()) continue;
    filename = entry.path().string();
    
    if(filename.empty() || gSystem->AccessPathName(filename.c_str()))
      {
	cout << "File " << filename << " not found...Aborting..." << endl;
	break;
      }
    else
      {
	if(verbosity > 0){
	  cout << "Reading in HEL::scaler for file " << filename << endl;
	}
      }

    reader_.setTags(1);
    reader_.open(filename.data()); //keep a pointer to the reader
    reader_.readDictionary(factory_);
    hipo::bank HEL(factory_.getSchema("HEL::scaler"));
    hipo::bank RAW(factory_.getSchema("RAW::scaler"));
    int entry_idx = 0;
    double RAW_tot_fcupgated = 0.0;
    double RAW_tot_fcupgated_pos = 0.0;
    double RAW_tot_fcupgated_neg = 0.0;
    double RAW_tot_fcupgated_zero = 0.0;
    double HEL_tot_fcupgated = 0.0;
    double HEL_tot_fcupgated_pos = 0.0;
    double HEL_tot_fcupgated_neg = 0.0;
    double HEL_tot_fcupgated_zero = 0.0;

    while(reader_.next()){
      reader_.read(event_);
      event_.getStructure(HEL);
      event_.getStructure(RAW);
      if(RAW.getRows()==0){
	continue;
      }
      
      HEL_fcupgated = HEL.getFloat("fcupgated",0);
      HEL_fcup = HEL.getFloat("fcup",0);
      HEL_slmgated = HEL.getFloat("slmgated",0);
      HEL_slm = HEL.getFloat("slm",0);
      HEL_clockgated = HEL.getFloat("clockgated",0);
      HEL_clock = HEL.getFloat("clock",0);
      HEL_helicity = HEL.getInt("helicity",0);
      HEL_helicityRaw = HEL.getInt("helicityRaw",0);
      
      HEL_tot_fcupgated+=HEL_fcupgated;
      if(HEL_helicity==1)
	HEL_tot_fcupgated_pos+=HEL_fcupgated;
      if(HEL_helicity==-1)
	HEL_tot_fcupgated_neg+=HEL_fcupgated;
      if(HEL_helicity==0)
	HEL_tot_fcupgated_zero+=HEL_fcupgated;

      RAW_fcupgated_33ms = 0.0;
      RAW_fcupgated_500us = 0.0;
      RAW_clockgated_33ms = 0.0;
      RAW_clockgated_500us = 0.0;

      
      for(int j = 0 ; j < RAW.getRows() ; j++){
	RAW_channel = RAW.getInt("channel",j);
	RAW_slot = (int)RAW.getByte("slot",j);
	if(RAW_channel==0 && RAW_slot==0)
	  RAW_fcupgated_33ms = RAW.getLong("value",j);
	else if(RAW_channel==2 && RAW_slot==0)
	  RAW_clockgated_33ms = RAW.getLong("value",j);
	else if(RAW_channel==32 && RAW_slot==0)
	  RAW_fcupgated_500us = RAW.getLong("value",j);
	else if(RAW_channel==34 && RAW_slot==0)
	  RAW_clockgated_500us = RAW.getLong("value",j);
      }
      
      double result_33ms = (RAW_fcupgated_33ms - offset * RAW_clockgated_33ms * pow(10,-6)) * atten / slope;
      double result_500us = (RAW_fcupgated_500us - offset * RAW_clockgated_500us * pow(10,-6)) * atten / slope;
      if(result_33ms>result_500us && result_33ms < 2){
	RAW_tot_fcupgated+=result_33ms;
	if(HEL_helicity==1)
	  RAW_tot_fcupgated_pos+=result_33ms;
	else if(HEL_helicity==-1)
	  RAW_tot_fcupgated_neg+=result_33ms;
	else if(HEL_helicity==0)
	  RAW_tot_fcupgated_zero+=result_33ms;
      }
      else if(result_500us>result_33ms && result_500us < 2){
	RAW_tot_fcupgated+=result_500us;
	if(HEL_helicity==1)
	  RAW_tot_fcupgated_pos+=result_500us;
	else if(HEL_helicity==-1)
	  RAW_tot_fcupgated_neg+=result_500us;
	else if(HEL_helicity==0)
	  RAW_tot_fcupgated_zero+=result_500us;
      }
      entry_idx++;
    }
   
    outFile_HEL << run << "," << idx_file << "," << entry_idx << "," << HEL_tot_fcupgated << "," << HEL_tot_fcupgated_pos << "," << HEL_tot_fcupgated_neg << "," << HEL_tot_fcupgated_zero << "," << RAW_tot_fcupgated << "," << RAW_tot_fcupgated_pos << "," << RAW_tot_fcupgated_neg << "," << RAW_tot_fcupgated_zero << "\n";

    reader_.open(filename.data()); //keep a pointer to the reader
    reader_.readDictionary(factory_);
    hipo::bank RUN(factory_.getSchema("RUN::scaler"));
    entry_idx = 0;
    double RUN_fcupgated_min = 999999999;
    double RUN_fcupgated_max = -999;
    double RUN_tot_livetime = 0.0;
    double RUN_fcup_min = 9999999999;
    double RUN_fcup_max = -999;

    while(reader_.next()){
      reader_.read(event_);
      event_.getStructure(RUN);

      if(RUN.getRows()==0){
	continue;
      }

      RUN_fcupgated = RUN.getFloat("fcupgated",0);
      RUN_fcup = RUN.getFloat("fcup",0);
      RUN_livetime = RUN.getFloat("livetime",0);
      
      // 9/13/2022
      // Unsure why livetime for some scaler entries is a huge negative number
      // For example, RUN::scaler in Run 16889
      // Just continue if this is the case?
      if(RUN_livetime<0)
	continue;

      if(RUN_fcupgated > RUN_fcupgated_max)
	RUN_fcupgated_max = RUN_fcupgated;
      else if(RUN_fcupgated < RUN_fcupgated_min)
	RUN_fcupgated_min = RUN_fcupgated;

      if(RUN_fcup > RUN_fcup_max)
	RUN_fcup_max = RUN_fcup;
      else if(RUN_fcup < RUN_fcup_min)
	RUN_fcup_min = RUN_fcup;
      
      RUN_tot_livetime+=RUN_livetime;
      entry_idx++;
    }

    outFile_RUN << run << "," << idx_file << "," << entry_idx << "," << RUN_fcupgated_min << "," << RUN_fcupgated_max << "," << RUN_fcupgated_max-RUN_fcupgated_min << "," << RUN_tot_livetime << "," << RUN_tot_livetime/entry_idx << "," << RUN_fcup_min << "," << RUN_fcup_max << "," << RUN_fcup_max - RUN_fcup_min << "," << RUN_tot_livetime/entry_idx * (RUN_fcup_max-RUN_fcup_min) << "\n";

  }

  outFile_HEL.close();
  outFile_RUN.close();


  return 0 ;
}
