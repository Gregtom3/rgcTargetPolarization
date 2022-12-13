int ProcessInclusive(const char * input_hipo = "/volatile/clas12/rg-c/production/ana_data/TBT/8.3.4/dst/train/sidisdvcs/sidisdvcs_16500.hipo",
		 const char * outdir = "./data/8.3.4/",
		 int run = 16500,
		 Double_t beamE = 10.5,
         Int_t hwp = 1,
         Double_t rcdb_tpol = 0.5,
         TString target = "ND3" ){

  // Create Output TFile with TTree
  TFile *file = new TFile(Form("%s/sidisdvcs_%d.root",outdir,run),"RECREATE");
  TTree *tree = new TTree("events","events");
  
  int    hel;
  double Px, Py, Pz, E, P;
  double Vz, Th, Phi;
  double x, Q2, y, W;

  tree->Branch("run", &run, "run/I");
  tree->Branch("hel", &hel, "hel/I");
  tree->Branch("Px", &Px, "Px/D");
  tree->Branch("Py", &Py, "Py/D");
  tree->Branch("Pz", &Pz, "Pz/D");
  tree->Branch("E", &E, "E/D");
  tree->Branch("Vz", &Vz, "Vz/D");
  tree->Branch("Th", &Th, "Th/D");
  tree->Branch("Phi", &Phi, "Phi/D");
  tree->Branch("x", &x, "x/D");
  tree->Branch("Q2", &Q2, "Q2/D");
  tree->Branch("y", &y, "y/D");
  tree->Branch("W", &W, "W/D");

  TVectorD vbeamE(1);
  vbeamE[0] = beamE;
  TVectorD vhwp(1);
  vhwp[0] = hwp;
  TVectorD vrcdb_tpol(1);
  vrcdb_tpol[0] = rcdb_tpol;
  file->WriteObject(&vbeamE, "beamE");
  file->WriteObject(&vhwp, "hwp");
  file->WriteObject(&vrcdb_tpol, "rcdb_tpol");
  file->WriteObject(&target, "target");
    
  // Feed hipo file to chain
  HipoChain chain;
  chain.Add(input_hipo);
  chain.SetReaderTags({0});  //create clas12reader with just tag 0 events

  auto config_c12=chain.GetC12Reader();
  config_c12->addAtLeastPid(11,1);    //exactly 1 electron

  // TURN OFF QADB
  config_c12->db()->turnOffQADB();
  //Add extra bank for reading and get its ID
  auto idx_RECPart= config_c12->addBank("REC::Particle");
  auto idx_HELOnline= config_c12->addBank("HEL::online");
  //Add an item in the bank for reading and get its ID
  auto iPid= config_c12->getBankOrder(idx_RECPart,"pid");
  auto iHelicity= config_c12->getBankOrder(idx_HELOnline,"helicity");
  
  //create particles before looping
  const double mE = 0.000511;
  const double mP = 0.938272;
  TLorentzVector vec_eIn;
  vec_eIn.SetPxPyPzE(0,0,sqrt(pow(beamE,2)-pow(mE,2)),beamE);
  TLorentzVector vec_eOut;  
  TLorentzVector vec_target;
  vec_target.SetPxPyPzE(0,0,0,mP);
  TLorentzVector vec_q;
  // create counting vars
  int Nplus = 0;
  int Nminus = 0;
  int Nzero = 0;
  int Nempty = 0;
  int Nloops = 0;
  cout<<"START EVENT LOOP "<<endl;
  //now get reference to (unique)ptr for accessing data in loop
  //this will point to the correct place when file changes
  auto& c12=chain.C12ref();
  //loop over all events in the file
  
  while(chain.Next()==true){
    
    Nloops++;
       
    if(c12->getDetParticles().empty())
      {
	Nempty++;
	continue;
      }

    hel = c12->getBank(idx_HELOnline)->getInt(iHelicity,0);
    
    if(hel==0){
      Nzero++;
      continue;
    }

    auto parts=c12->getDetParticles();       
    for(unsigned int idx = 0 ; idx < parts.size(); idx++){
      auto particle = parts.at(idx);
      int pid = particle->getPid();
      if(pid!=11) // Only analyze the electrons
	continue;
      P = particle->getP();
      double M = particle->getPdgMass();
      E = sqrt(P*P+M*M);
      Th = particle->getTheta();
      Phi = particle->getPhi();
      Px = P*sin(Th)*cos(Phi);
      Py = P*sin(Th)*sin(Phi);
      Pz = P*cos(Th);
      Vz = particle->par()->getVz();
      
      vec_eOut.SetPxPyPzE(Px,Py,Pz,E);
      vec_q = vec_eIn-vec_eOut;
      Q2 = -vec_q.M2();
      y  = (vec_target*vec_q)/(vec_target*vec_eIn);
      x  = Q2/((vec_target+vec_eIn).M2()*y);
      W  = (vec_eIn+vec_target-vec_eOut).M();
        
      tree->Fill();
    }    
  }  
  return 0;
  
}
