//********************************************************************
 /*  SS_Label_FUNCTION 25 evaluate_the_objective_function */
FUNCTION void evaluate_the_objective_function()
  {
  surv_like.initialize();   Q_dev_like.initialize(); disc_like.initialize(); length_like.initialize(); age_like.initialize();
  sizeage_like.initialize(); parm_like.initialize(); parm_dev_like.initialize();
  mnwt_like.initialize(); equ_catch_like.initialize(); recr_like.initialize(); Fcast_recr_like.initialize();
  catch_like.initialize(); Morphcomp_like.initialize(); TG_like1.initialize(); TG_like2.initialize();
  length_like_tot.initialize(); age_like_tot.initialize();
  obj_fun=0.0;

    int k_phase=current_phase();
    int fs;
    if(k_phase>max_lambda_phase) k_phase=max_lambda_phase;


//Q_setup for 3.30
// 1:  link type
// 2:  extra input for link, i.e. mirror fleet
// 3:  0/1 to select extra sd parameter
// 4:  0/1 for biasadj or not
// 5:  0/1 to float  k=4;

//  Link types
//  1  simple q, 1 parm
//  2  mirror simple q, 1 mirrored parameter
//  3  q and power, 2 parm

    if(Svy_N>0)
    {
      for (f=1;f<=Nfleet;f++)
      if(surv_lambda(f,k_phase)>0.0 || save_for_report>0)      // skip if zero emphasis
      {
        if(Svy_N_fleet(f)>0)
        {
          Svy_se_use(f) = Svy_se(f);
          if(Q_setup(f,3)>0)
            {
              Svy_se_use(f)+=Q_parm(Q_setup_parms(f,2));  // add extra stderr
            }
  // SS_Label_Info_25.1.1 #combine for super-periods
          for (j=1;j<=Svy_super_N(f);j++)
          {
            temp=0.0;
            for (i=Svy_super_start(f,j);i<=Svy_super_end(f,j);i++) {temp+=Svy_est(f,i)*Svy_super_weight(f,i);} // combine across range of observations
//  sampwt sums to 1.0, so temp contains the weighted average
            for (i=Svy_super_start(f,j);i<=Svy_super_end(f,j);i++) {Svy_est(f,i)=temp;}   // assign average to each obs
          }

  // SS_Label_Info_25.1.2 #apply catchability, Q
          if(Q_setup(f,5)>0 )  //  do float Q
          {                                       //  NOTE:  cannot use float option if error type is normal
            temp=0.; temp1=0.; temp2=0.;
            for (i=1;i<=Svy_N_fleet(f);i++)
            {
              if(Svy_use(f,i) > 0)
              {
                temp2 += (Svy_obs_log(f,i)-Svy_est(f,i))/square(Svy_se_use(f,i));
                temp += 1.0/square(Svy_se_use(f,i));
                temp1 += 1.;
              }
            }

            if(Q_setup(f,4)==0)                               // mean q, with nobiasadjustment
            {
              Svy_log_q(f) +=temp2/temp;
              Svy_est(f) += temp2/temp;
            }
            else                  // for value = 1 or 5       // mean q with variance bias adjustment
            {
              Svy_log_q(f) += (temp2 + temp1*0.5)/temp;
              Svy_est(f) += (temp2 + temp1*0.5)/temp;
            }
            Q_parm(Q_setup_parms(f,1))=Svy_log_q(f,1);    // base Q  So this sets parameter equal to the scaling coefficient and can then have a prior

            if(Svy_errtype(f)==-1)  // normal
            {
              Svy_q(f) = Svy_log_q(f);        //  q already in  arithmetic space
            }
            else
            {
              Svy_q(f) = mfexp(Svy_log_q(f));        // get q in arithmetic space
            }
          }
  /*
          else if(Q_setup(f,1)==2)        // mirror Q from lower numbered survey
                                           // because Q is a vector for each observation, the mirror is to the first observation's Q
                                           // so time-varying property cannot be mirrored
          {Svy_log_q(f) = Svy_log_q(Q_setup(f,2),1);}

          else   //  Q from parameter
                 //   add code here for more link options
                 //  NOTE:  if Q_setup(f,1)==3  then the power function is used in SS_expval to adjust svy_exp by that function
                 //  probably better to move this Q parameter code to right after the call to SS_timevaryparm  and to keep only the Q float code here
          {
            if(Qparm_timevary(Q_setup_parms(f,1))==0) //  not time-varying
            {
              Svy_log_q(f)=Q_parm(Q_setup_parms(f,1));  //  set to base parameter value
            }
            else
            {
              for(j=1;j<=Svy_N_fleet(f);j++)
              {
                y=Svy_yr(f,j);
                Svy_log_q(f,j)=parm_timevary(Qparm_timevary(Q_setup_parms(f,1)),y);
              }
            }
          }

  // SS_Label_Info_25.1.3 #log or not
   */

  // SS_Label_Info_25.1.4 #calc the logL
          if(Svy_errtype(f)==0)  // lognormal
          {
            for (i=1;i<=Svy_N_fleet(f);i++)
            if(Svy_use(f,i)>0)
            {
              surv_like(f) +=0.5*square( ( Svy_obs_log(f,i)-Svy_est(f,i)) / Svy_se_use(f,i)) + sd_offset*log(Svy_se_use(f,i));
//            should add a term for 0.5*s^2 for bias adjustment so that parameter approach will be same as the  biasadjusted scaling approach
            }
          }
          else if (Svy_errtype(f)>0)        // t-distribution
          {
            dvariable df = Svy_errtype(f);
            for (i=1;i<=Svy_N_fleet(f);i++)
            if(Svy_use(f,i)>0)
            {
              surv_like(f) +=((df+1.)/2.)*log((1.+square((Svy_obs_log(f,i)-Svy_est(f,i) ))/(df*square(Svy_se_use(f,i))) )) + sd_offset*log(Svy_se_use(f,i));
            }
          }
          else if(Svy_errtype(f)==-1)  // normal
          {
            for (i=1;i<=Svy_N_fleet(f);i++)
            {
              if(Svy_use(f,i)>0)
              {
                surv_like(f) +=0.5*square( ( Svy_obs(f,i)-Svy_est(f,i) ) / Svy_se_use(f,i)) + sd_offset*log(Svy_se_use(f,i));
              }
            }
          }

        }    // end having obs for this survey
      }
       if(do_once==1) cout<<" did survey obj_fun "<<surv_like<<endl;
    }

  //  SS_Label_Info_25.2 #Fit to discard
  if(nobs_disc>0)
  {
    for (f=1;f<=Nfleet;f++)
    if(disc_lambda(f,k_phase)>0.0 || save_for_report>0)
    {
      if(disc_N_fleet(f)>0)
      {
        for (j=1;j<=N_suprper_disc(f);j++)                  // do super years
        {
          temp=0.0;
          for (i=suprper_disc1(f,j);i<=suprper_disc2(f,j);i++) {temp+=exp_disc(f,i)*suprper_disc_sampwt(f,i);} // combine across range of observations
          for (i=suprper_disc1(f,j);i<=suprper_disc2(f,j);i++) {exp_disc(f,i)=temp;}   // assign back to each obs
        }

        if(disc_errtype(f)>=1)  // T -distribution
        {
          for (i=1;i<=disc_N_fleet(f);i++)
          if(yr_disc_use(f,i)>=0.0)
          {
            disc_like(f) +=0.5*(disc_errtype(f)+1.)*log((1.+square(obs_disc(f,i)-exp_disc(f,i))/(disc_errtype(f)*square(sd_disc(f,i))) )) + sd_offset*log(sd_disc(f,i));
          }
        }
        else if (disc_errtype(f)==0)  // normal error, with input CV
        {
          for (i=1;i<=disc_N_fleet(f);i++)
          if(yr_disc_use(f,i)>=0.0)
          {
            disc_like(f) +=0.5*square( (obs_disc(f,i)-exp_disc(f,i)) / sd_disc(f,i)) + sd_offset*log(sd_disc(f,i));
          }
        }
        else if (disc_errtype(f)==-1)  // normal error with input se
        {
          for (i=1;i<=disc_N_fleet(f);i++)
          if(yr_disc_use(f,i)>=0.0)
          {
            disc_like(f) +=0.5*square( (obs_disc(f,i)-exp_disc(f,i)) / sd_disc(f,i)) + sd_offset*log(sd_disc(f,i));
          }
        }
        else if (disc_errtype(f)==-2)  // lognormal  where input cv_disc must contain se in log space
        {
          for (i=1;i<=disc_N_fleet(f);i++)
          if(yr_disc_use(f,i)>=0.0)
          {
            disc_like(f) +=0.5*square( log(obs_disc(f,i)/exp_disc(f,i)) / sd_disc(f,i)) + sd_offset*log(sd_disc(f,i));
          }
        }
        else if (disc_errtype(f)==-3)  // trunc normal error, with input CV
        {
          for (i=1;i<=disc_N_fleet(f);i++)
          if(yr_disc_use(f,i)>=0.0)
          {
            disc_like(f) +=0.5*square( (obs_disc(f,i)-exp_disc(f,i) ) / sd_disc(f,i)) - log(cumd_norm( (1 - exp_disc(f,i)) / sd_disc(f,i) ) - cumd_norm( (0 - exp_disc(f,i)) / sd_disc(f,i) ));
          }
        }
        else
        {
            N_warn++; cout<<" EXIT - see warning "<<endl; warning<<" discard error type for fleet "<<f<<" = "<<disc_errtype(f)<<" should be -3, -2, -1, 0, or >=1"<<endl; cout<<" fatal error, see warning"<<endl; exit(1);
        }
      }
    }
    if(do_once==1) cout<<" did discard obj_fun "<<disc_like<<endl;
  }

  //  SS_Label_Info_25.3 #Fit to mean body wt
   if(nobs_mnwt>0)
   {
     for (i=1;i<=nobs_mnwt;i++)
     if(mnwtdata(5,i)>0. && mnwtdata(3,i)>0.)
     {
       mnwt_like(mnwtdata(3,i)) +=0.5*(DF_bodywt+1.)*log(1.+square(mnwtdata(5,i)-exp_mnwt(i))/mnwtdata(8,i))+ mnwtdata(9,i);
     }
      // mnwtdata(6,i)+=var_adjust(3,mnwtdata(3,i));  adjusted input error as a CV
      // if(mnwtdata(6,i)<=0.0) mnwtdata(6,i)=0.001;
      // mnwtdata(7,i)=mnwtdata(5,i)*mnwtdata(6,i);  se = obs*CV
      // mnwtdata(8,i)=DF_bodywt*square(mnwtdata(7,i));   error as T-dist
      // mnwtdata(9,i)=sd_offset*log(mnwtdata(7,i));  for the -log(s) component

     if(do_once==1) cout<<" did meanwt obj_fun "<<mnwt_like<<endl;
   }

  //  SS_Label_Info_25.4 #Fit to length comp
   if(Nobs_l_tot>0)
   {
   for (f=1;f<=Nfleet;f++)
   if(length_lambda(f,k_phase)>0.0 || save_for_report>0)
    {
    if(Nobs_l(f)>=1)
    {

     for (j=1;j<=N_suprper_l(f);j++)                  // do each super period
     {
       exp_l_temp_dat.initialize();
       for (i=suprper_l1(f,j);i<=suprper_l2(f,j);i++)
       {
         exp_l_temp_dat+=exp_l(f,i)*suprper_l_sampwt(f,i);  // combine across range of observations
       }
//       exp_l_temp_dat/=sum(exp_l_temp_dat);   // normalize not needed because converted to proportions later
       for (i=suprper_l1(f,j);i<=suprper_l2(f,j);i++)
       {
         exp_l(f,i)=exp_l_temp_dat;   // assign back to all obs
       }
     }

     for (i=1;i<=Nobs_l(f);i++)
     {
     length_like(f,i) = -offset_l(f,i);  //  so a perfect fit will approach 0.0
     if(gender==2)
     {
       if(gen_l(f,i)==0)
       {
         for (z=1;z<=nlen_bin;z++) {exp_l(f,i,z)+=exp_l(f,i,z+nlen_bin);}
         exp_l(f,i)(nlen_binP,nlen_bin2)=0.00;
       }
       else if(gen_l(f,i)==1)                   // female only
       {exp_l(f,i)(nlen_binP,nlen_bin2)=0.00;}
       else if(gen_l(f,i)==2)                   // male only
       {exp_l(f,i)(1,nlen_bin)=0.00;}
       else if(gen_l(f,i)==3 && CombGender_L(f)>0)
       {
         for (z=1;z<=CombGender_L(f);z++)
         {exp_l(f,i,z)+=exp_l(f,i,z+nlen_bin);  exp_l(f,i,z+nlen_bin)=0.00;}
       }
     }
     exp_l(f,i) /= sum(exp_l(f,i));
     tails_w=ivector(tails_l(f,i));

        if(gen_l(f,i)!=2)
        {
         if(tails_w(1)>1)
           {exp_l(f,i,tails_w(1))=sum(exp_l(f,i)(1,tails_w(1)));  exp_l(f,i)(1,tails_w(1)-1)=0.;}
         if(tails_w(2)<nlen_bin)
           {exp_l(f,i,tails_w(2))=sum(exp_l(f,i)(tails_w(2),nlen_bin));  exp_l(f,i)(tails_w(2)+1,nlen_bin)=0.;}
         exp_l(f,i)(tails_w(1),tails_w(2))+= min_comp_L(f);
        }

        if(gender==2 && gen_l(f,i)>=2)
        {
         if(tails_w(3)>nlen_binP)
           {exp_l(f,i,tails_w(3))=sum(exp_l(f,i)(nlen_binP,tails_w(3)));  exp_l(f,i)(nlen_binP,tails_w(3)-1)=0.;}
         if(tails_w(4)<nlen_bin2)
           {exp_l(f,i,tails_w(4))=sum(exp_l(f,i)(tails_w(4),nlen_bin2));  exp_l(f,i)(tails_w(4)+1,nlen_bin2)=0.;}
         exp_l(f,i)(tails_w(3),tails_w(4))+= min_comp_L(f);
        }
        exp_l(f,i) /= sum(exp_l(f,i));

     if(header_l(f,i,3)>0)
     {
      if(Comp_Err_L(f)==0) // multinomial
      {
        // get female or combined sex logL
       if(gen_l(f,i) !=2) length_like(f,i) -= nsamp_l(f,i) *
       obs_l(f,i)(tails_w(1),tails_w(2)) * log(exp_l(f,i)(tails_w(1),tails_w(2)));
       //  add male logL
       if(gen_l(f,i) >=2 && gender==2) length_like(f,i) -= nsamp_l(f,i) *
       obs_l(f,i)(tails_w(3),tails_w(4)) * log(exp_l(f,i)(tails_w(3),tails_w(4)));
      }
      else  //  dirichlet
      {
// from Thorson:  NLL -= gammln(A) - gammln(ninput_t(t)+A) + sum(gammln(ninput_t(t)*extract_row(pobs_ta,t) + A*extract_row(pexp_ta,t))) - sum(lgamma(A*extract_row(pexp_ta,t))) \
//        dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_L2(f)))*nsamp_l(f,i);
        if(Comp_Err_L(f)==1) dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_L2(f)))*nsamp_l(f,i);
        if(Comp_Err_L(f)==2) dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_L2(f)));
//                             dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_L2(f)));
        temp = gammln(dirichlet_Parm) - gammln(nsamp_l(f,i)+dirichlet_Parm);
        // get female or combined sex logL
        if(gen_l(f,i) !=2) //  so not male only
        {
          temp+=sum(gammln(nsamp_l(f,i)*  obs_l(f,i)(tails_w(1),tails_w(2))
                         + dirichlet_Parm*exp_l(f,i)(tails_w(1),tails_w(2))));
          temp-=sum(gammln(dirichlet_Parm*exp_l(f,i)(tails_w(1),tails_w(2))));
        }
        //  add male logL
        if(gen_l(f,i) >=2 && gender==2)
        {
          temp+=sum(gammln(nsamp_l(f,i)*  obs_l(f,i)(tails_w(3),tails_w(4))
                         + dirichlet_Parm*exp_l(f,i)(tails_w(3),tails_w(4))));
          temp-=sum(gammln(dirichlet_Parm*exp_l(f,i)(tails_w(3),tails_w(4))));
        }
        length_like(f,i)-=temp;
      }
     }
     }
     length_like_tot(f)=sum(length_like(f));
    }
   }
    if(do_once==1) cout<<" did lencomp obj_fun  " <<length_like_tot<<endl;
   }

  //  SS_Label_Info_25.5 #Fit to age composition
  if(Nobs_a_tot>0)
  {
    for (f=1;f<=Nfleet;f++)
    if(age_lambda(f,k_phase)>0.0 || save_for_report>0)
    {
      if(Nobs_a(f)>=1)
      {
        for (j=1;j<=N_suprper_a(f);j++)                  // do super years  Max of 20 allowed per type(f)
        {
          exp_a_temp.initialize();
          for (i=suprper_a1(f,j);i<=suprper_a2(f,j);i++)
          {
            exp_a_temp+=exp_a(f,i)*suprper_a_sampwt(f,i);  // combine across range of observations
          }
//          exp_a_temp/=(1.0e-15+sum(exp_a_temp));                                        // normalize
          for (i=suprper_a1(f,j);i<=suprper_a2(f,j);i++) exp_a(f,i)=exp_a_temp;   // assign back to each original obs
        }

        for (i=1;i<=Nobs_a(f);i++)
        {
          age_like(f,i) = -offset_a(f,i);  //  so a perfect fit will approach 0.0
          if(gender==2)
          {
            if(gen_a(f,i)==0)                         // combined sex observation
            {
              for (z=1;z<=n_abins;z++) {exp_a(f,i,z)+=exp_a(f,i,z+n_abins);}
              exp_a(f,i)(n_abins1,n_abins2)=0.00;
            }
            else if(gen_a(f,i)==1)                   // female only
            {exp_a(f,i)(n_abins1,n_abins2)=0.00;}
            else if(gen_a(f,i)==2)                   // male only
            {exp_a(f,i)(1,n_abins)=0.00;}
            else if(gen_a(f,i)==3 && CombGender_A(f)>0)
            {
              for (z=1;z<=CombGender_A(f);z++)
              {exp_a(f,i,z)+=exp_a(f,i,z+n_abins);  exp_a(f,i,z+n_abins)=0.00;}
            }
          }
          exp_a(f,i) /= (1.0e-15+sum(exp_a(f,i)));                      // proportion at binned age

          tails_w=ivector(tails_a(f,i));
          if(gen_a(f,i)!=2)
          {
            if(tails_w(1)>1)
            {exp_a(f,i,tails_w(1))=sum(exp_a(f,i)(1,tails_w(1)));  exp_a(f,i)(1,tails_w(1)-1)=0.;}
            if(tails_w(2)<n_abins)
            {exp_a(f,i,tails_w(2))=sum(exp_a(f,i)(tails_w(2),n_abins));  exp_a(f,i)(tails_w(2)+1,n_abins)=0.;}
            exp_a(f,i)(tails_w(1),tails_w(2))+= min_comp_A(f);
          }

          if(gender==2 && gen_a(f,i)>=2)
          {
            if(tails_w(3)>n_abins1)
            {exp_a(f,i,tails_w(3))=sum(exp_a(f,i)(n_abins1,tails_w(3)));  exp_a(f,i)(n_abins1,tails_w(3)-1)=0.;}
            if(tails_w(4)<n_abins2)
            {exp_a(f,i,tails_w(4))=sum(exp_a(f,i)(tails_w(4),n_abins2));  exp_a(f,i)(tails_w(4)+1,n_abins2)=0.;}
            exp_a(f,i)(tails_w(3),tails_w(4))+= min_comp_A(f);
          }

          exp_a(f,i) /= (1.0e-15+sum(exp_a(f,i)));

          if(header_a(f,i,3)>0)
          {
            if(Comp_Err_A(f)==0)  //  multinomial
            {
              if(gen_a(f,i) !=2) age_like(f,i) -= nsamp_a(f,i) *
              obs_a(f,i)(tails_w(1),tails_w(2)) * log(exp_a(f,i)(tails_w(1),tails_w(2)));
              if(gen_a(f,i) >=2 && gender==2) age_like(f,i) -= nsamp_a(f,i) *
              obs_a(f,i)(tails_w(3),tails_w(4)) * log(exp_a(f,i)(tails_w(3),tails_w(4)));
            }
            else  // dirichlet
            {
// from Thorson:  NLL -= gammln(A) - gammln(ninput_t(t)+A) + sum(gammln(ninput_t(t)*extract_row(pobs_ta,t) + A*extract_row(pexp_ta,t))) - sum(lgamma(A*extract_row(pexp_ta,t))) \
//              dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_A2(f)))*nsamp_a(f,i);
              if(Comp_Err_A(f)==1) dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_A2(f)))*nsamp_a(f,i);
              if(Comp_Err_A(f)==2) dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_A2(f)));
//              dirichlet_Parm=mfexp(selparm(Comp_Err_Parm_Start+Comp_Err_A2(f)));
              temp = gammln(dirichlet_Parm) - gammln(nsamp_a(f,i)+dirichlet_Parm);
              // get female or combined sex logL
              if(gen_a(f,i) !=2) //  so not male only
              {
                temp+=sum(gammln(nsamp_a(f,i)*  obs_a(f,i)(tails_w(1),tails_w(2))
                               + dirichlet_Parm*exp_a(f,i)(tails_w(1),tails_w(2))));
                temp-=sum(gammln(dirichlet_Parm*exp_a(f,i)(tails_w(1),tails_w(2))));
              }
              //  add male logL
              if(gen_a(f,i) >=2 && gender==2)
              {
                temp+=sum(gammln(nsamp_a(f,i)*  obs_a(f,i)(tails_w(3),tails_w(4))
                               + dirichlet_Parm*exp_a(f,i)(tails_w(3),tails_w(4))));
                temp-=sum(gammln(dirichlet_Parm*exp_a(f,i)(tails_w(3),tails_w(4))));
              }
              age_like(f,i)-=temp;
            }
          }
        }
        age_like_tot(f)=sum(age_like(f));
      }
    }
    if(do_once==1) cout<<" did agecomp obj_fun "<<age_like_tot<<endl;
  }

  //  SS_Label_Info_25.6 #Fit to mean size@age
    if(nobs_ms_tot>0)
    {
      for (f=1;f<=Nfleet;f++)
      if(Nobs_ms(f)>0 && sizeage_lambda(f,k_phase)>0.0)
      {
         for (j=1;j<=N_suprper_ms(f);j++)
         {
           exp_a_temp.initialize();
           for (i=suprper_ms1(f,j);i<=suprper_ms2(f,j);i++) {exp_a_temp+=exp_ms(f,i)*suprper_ms_sampwt(f,i);} // combine across range of observations
           for (i=suprper_ms1(f,j);i<=suprper_ms2(f,j);i++) exp_ms(f,i)=exp_a_temp;   // assign back to each original obs
         }

         for (i=1;i<=Nobs_ms(f);i++)
         if(header_ms(f,i,3)>0)
         {
           for (b=1;b<=n_abins2;b++)
           {
             if(obs_ms_n(f,i,b)>0 && obs_ms(f,i,b)>0)
             {
               sizeage_like(f) += 0.5*square((obs_ms(f,i,b) -exp_ms(f,i,b)) / (exp_ms_sq(f,i,b)/obs_ms_n(f,i,b)))
               + sd_offset*log(exp_ms_sq(f,i,b)/obs_ms_n(f,i,b));
               //  where:        obs_ms_n(f,i,b)=sqrt(var_adjust(6,f)*obs_ms_n(f,i,b));
             }
           }
         }
       }
        if(do_once==1) cout<<" did meanlength obj_fun "<<sizeage_like<<endl;
    }

  //  SS_Label_Info_25.7 #Fit to generalized Size composition
    if(SzFreq_Nmeth>0)       //  have some sizefreq data
    {
      // create super-period expected values
      for (j=1;j<=N_suprper_SzFreq;j++)
      {
        a=suprper_SzFreq_start(j);  // get observation index
        SzFreq_exp(a)*=suprper_SzFreq_sampwt(a);  //  start creating weighted average
        for (iobs=a+1;iobs<=suprper_SzFreq_end(j);iobs++) {SzFreq_exp(a)+=SzFreq_exp(iobs)*suprper_SzFreq_sampwt(iobs);}  //  combine into the first obs of this superperiod
        for (iobs=a+1;iobs<=suprper_SzFreq_end(j);iobs++) {SzFreq_exp(iobs)=SzFreq_exp(a);}  //  assign back to all obs
      }

      SzFreq_like=-SzFreq_like_base;  // initializes
      for (iobs=1;iobs<=SzFreq_totobs;iobs++)
      {
        if(SzFreq_obs_hdr(iobs,3)>0)
        {
          k=SzFreq_obs_hdr(iobs,6);
          f=abs(SzFreq_obs_hdr(iobs,3));
          z1=SzFreq_obs_hdr(iobs,7);
          z2=SzFreq_obs_hdr(iobs,8);
          //  is there a check for ignored obs with f<0?
          SzFreq_like(SzFreq_LikeComponent(f,k))-=SzFreq_sampleN(iobs)*SzFreq_obs(iobs)(z1,z2)*log(SzFreq_exp(iobs)(z1,z2));
        }
      }

      if(do_once==1) cout<<" did sizefreq obj_fun: "<<SzFreq_like<<endl;
    }

  //  SS_Label_Info_25.8 #Fit to morph composition
    if(Do_Morphcomp>0)
    {
      for (iobs=1;iobs<=Morphcomp_nobs;iobs++)
      {
        k=5+Morphcomp_nmorph;
        Morphcomp_exp(iobs)(6,k) /= sum(Morphcomp_exp(iobs)(6,k));
        Morphcomp_exp(iobs)(6,k) += Morphcomp_mincomp;
        Morphcomp_exp(iobs)(6,k) /= 1.+Morphcomp_mincomp*Morphcomp_nmorph;
        if(Morphcomp_obs(iobs,5)>0.) Morphcomp_like -= Morphcomp_obs(iobs,5)*Morphcomp_obs(iobs)(6,k) * log(elem_div(Morphcomp_exp(iobs)(6,k),Morphcomp_obs(iobs)(6,k)));
      }
    if(do_once==1) cout<<" did morphcomp obj_fun "<<Morphcomp_like<<endl;
    }

  //  SS_Label_Info_25.9 #Fit to tag-recapture
    if(Do_TG>0)
    {
      for (TG=1;TG<=N_TG;TG++)
      {
        overdisp=TG_parm(2*N_TG+TG);
        for (TG_t=TG_mixperiod;TG_t<=TG_endtime(TG);TG_t++)
        {
          TG_recap_exp(TG,TG_t)(1,Nfleet)+=1.0e-6;  // add a tiny amount
          TG_recap_exp(TG,TG_t,0) = sum(TG_recap_exp(TG,TG_t)(1,Nfleet));
          TG_recap_exp(TG,TG_t)(1,Nfleet)/=TG_recap_exp(TG,TG_t,0);
          if(Nfleet>1) TG_like1(TG)-=TG_recap_obs(TG,TG_t,0)* (TG_recap_obs(TG,TG_t)(1,Nfleet) * log(TG_recap_exp(TG,TG_t)(1,Nfleet)));
          TG_like2(TG)-=log_negbinomial_density(TG_recap_obs(TG,TG_t,0),TG_recap_exp(TG,TG_t,0),overdisp);
        }
      }
    if(do_once==1) cout<<" did tag obj_fun "<<TG_like1<<endl<<TG_like2<<endl;
    }

  //  SS_Label_Info_25.10 #Fit to initial equilibrium catch
    if(init_equ_lambda(k_phase)>0.0)
    {
      for (s=1;s<=nseas;s++)
      for (f=1;f<=Nfleet;f++)
      {
        if(fleet_type(f)==1 &&  obs_equ_catch(s,f)>0.0)
          {equ_catch_like += 0.5*square( (log(1.1*obs_equ_catch(s,f)) -log(est_equ_catch(s,f)*catch_mult(styr-1,f)+0.1*obs_equ_catch(s,f))) / catch_se(styr-1,f));}
      }
      if(do_once==1) cout<<" initequ_catch -log(L) "<<equ_catch_like<<endl;
    }

  //  SS_Label_Info_25.11 #Fit to catch by fleet/season
    if(F_Method>1)
    {
      for (f=1;f<=Nfleet;f++)
      {
        if(catchunits(f)==1)
        {i=3;}  //  biomass
        else
        {i=6;}  //  numbers

        for (t=styr;t<=TimeMax;t++)
        {
          if(fleet_type(f)==1 && catch_ret_obs(f,t)>0.0)
          {
//          catch_like(f) += 0.5*square( (log(catch_ret_obs(f,t)) -log(catch_fleet(t,f,i)+0.000001)) / catch_se(t,f));
            catch_like(f) += 0.5*square( (log(1.1*catch_ret_obs(f,t)) -log(catch_fleet(t,f,i)*catch_mult(y,f)+0.1*catch_ret_obs(f,t))) / catch_se(t,f));
          }
        }
      }
      if(do_once==1) cout<<" catch -log(L) "<<catch_like<<endl;
    }

  //  SS_Label_Info_25.12 #Likelihood for the recruitment deviations
//The recruitment prior is assumed to be a lognormal pdf with expected
// value equal to the deterministic stock-recruitment curve          // SS_Label_260
//  R1 deviation is weighted by ave_age because R1 represents a time series of recruitments
//  SR_parm(N_SRparm+1) is sigmaR
//  SR_parm(N_SRparm+4) is rho, the autocorrelation coefficient
//  POP code from Ianelli
//  if (rho>0)
//    for (i=styr_rec+1;i<=endyr;i++)
//      rec_like(1) += square((chi(i)- rho*chi(i-1)) /(sqrt(1.-rho*rho))) / (2.*sigmaRsq) + log(sigr);
//  else
//    rec_like(1)    = (norm2( chi +  sigmaRsq/2. ) / (2*sigmaRsq)) / (2.*sigmaRsq) + size_count(chi)*log(sigr);

    if(recrdev_lambda(k_phase)>0.0 && (do_recdev>0 || recdev_do_early>0) )
    {
      recr_like = sd_offset_rec*log(sigmaR);
      // where sd_offset_rec takes account for the number of recruitment years fully estimated
      // this is calculated as the sum of the biasadj vector
      if(SR_autocorr==0)
      {
      recr_like += norm2(recdev(recdev_first,recdev_end))/two_sigmaRsq;
      }
      else
      {
        rho=SR_parm(N_SRparm2);
        recr_like += square(recdev(recdev_first))/two_sigmaRsq;
        for (y=recdev_first+1;y<=recdev_end;y++)
        {
          recr_like += square(recdev(y)-rho*recdev(y-1)) / ((1.0-rho*rho)*two_sigmaRsq);
        }
      }
      recr_like += 0.5 * square( log(R1/R1_exp) / (sigmaR/ave_age) );
      if(do_once==1) cout<<" did recruitdev obj_fun "<<recr_like<<endl;
    }
    if(Do_Forecast>0)
    {
      if(recdev_end<endyr)
      {
        Fcast_recr_like = Fcast_recr_lambda*(norm2(Fcast_recruitments(recdev_end+1,endyr)))/two_sigmaRsq;
//        Fcast_recr_like += sd_offset_fore*log(sigmaR);  this is now part of the recr_liker logL calculated above
      }
      else
      {Fcast_recr_like=0.0;}
      if(Do_Impl_Error>0) Fcast_recr_like+=(norm2(Fcast_impl_error(endyr+1,YrMax)))/(2.0*Impl_Error_Std*Impl_Error_Std);  // implementation error
      if(SR_autocorr==0)
      {
        Fcast_recr_like += (norm2(Fcast_recruitments(endyr+1,YrMax)))/two_sigmaRsq;
      }
      else
      {
        Fcast_recr_like += square(Fcast_recruitments(recdev_end+1)-rho*recdev(recdev_end)) / ((1.0-rho*rho)*two_sigmaRsq);  //  for the transition year
        for(y=recdev_end+2;y<=YrMax;y++)
        {Fcast_recr_like += square(Fcast_recruitments(y)-rho*Fcast_recruitments(y-1)) / ((1.0-rho*rho)*two_sigmaRsq);}
      }
    }

  //  SS_Label_Info_25.13 #Penalty for the parameter priors
    dvariable mu; dvariable tau; dvariable Aprior; dvariable Bprior;
    int Ptype;
    dvariable Pconst;
    Pconst=0.0001;

    if(parm_prior_lambda(k_phase)>0.0 || Do_all_priors>0)
    {
      for (i=1;i<=N_MGparm2;i++)
      if(MGparm_PRtype(i)>0 && (active(MGparm(i))|| Do_all_priors>0))
        {
        MGparm_Like(i)=Get_Prior(MGparm_PRtype(i), MGparm_LO(i), MGparm_HI(i), MGparm_PR(i), MGparm_CV(i), MGparm(i));
        parm_like+=MGparm_Like(i);
        }
      for (i=1;i<=N_init_F;i++)
      if(init_F_PRtype(i)>0 && (active(init_F(i))|| Do_all_priors>0))
        {
        init_F_Like(i)=Get_Prior(init_F_PRtype(i), init_F_LO(i), init_F_HI(i), init_F_PR(i), init_F_CV(i), init_F(i));
        parm_like+=init_F_Like(i);
        }

      for (i=1;i<=Q_Npar2;i++)
      if(Q_parm_PRtype(i)>0 && (active(Q_parm(i))|| Do_all_priors>0))
        {
        Q_parm_Like(i)=Get_Prior(Q_parm_PRtype(i), Q_parm_LO(i), Q_parm_HI(i), Q_parm_PR(i), Q_parm_CV(i), Q_parm(i));
        parm_like+=Q_parm_Like(i);
        }

      for (i=1;i<=N_selparm2;i++)
      if(selparm_PRtype(i)>0 && (active(selparm(i))|| Do_all_priors>0))
        {
        selparm_Like(i)=Get_Prior(selparm_PRtype(i), selparm_LO(i), selparm_HI(i), selparm_PR(i), selparm_CV(i), selparm(i));
        parm_like+=selparm_Like(i);
        }
    if(Do_TG>0)
    {
      k=3*N_TG+2*Nfleet1;
      for (i=1;i<=k;i++)
      if(TG_parm2(i,5)>0 && (active(TG_parm(i))|| Do_all_priors>0))
      {
        TG_parm_Like(i)=Get_Prior(TG_parm2(i,6), TG_parm_LO(i), TG_parm_HI(i), TG_parm2(i,4), TG_parm2(i,5), TG_parm(i));
        parm_like+=TG_parm_Like(i);
      }
    }

    for (i=1;i<=N_SRparm3;i++)
      if(SR_parm_PRtype(i)>0 && (active(SR_parm(i))|| Do_all_priors>0))
        {
        SR_parm_Like(i)=Get_Prior(SR_parm_PRtype(i), SR_parm_LO(i), SR_parm_HI(i), SR_parm_PR(i), SR_parm_CV(i), SR_parm(i));
        parm_like+=SR_parm_Like(i);
        }
  //  SS_Label_Info_25.14 #logL for recdev_cycle
    if(recdev_cycle>0)
    {
      temp=0.0; temp1=0.0;
      for (i=1;i<=recdev_cycle;i++)
      {
        if(recdev_cycle_parm_RD(i,5)>0 && (active(recdev_cycle_parm(i))|| Do_all_priors>0))
        {
          recdev_cycle_Like(i)=Get_Prior(recdev_cycle_parm_RD(i,6), recdev_cycle_parm_RD(i,1), recdev_cycle_parm_RD(i,2), recdev_cycle_parm_RD(i,4), recdev_cycle_parm_RD(i,5), recdev_cycle_parm(i));
          parm_like+=recdev_cycle_Like(i);
          temp+=mfexp(recdev_cycle_parm(i));
          temp1+=1.0;
        }
      }
      temp-=temp1;
      parm_like+=10000.*temp*temp;  //  similar to ADMB's approach to getting zero-centered dev_vectors
    }
    }
  //  SS_Label_Info_25.15 #logL for parameter process errors (devs)
    {

  //  new code to match mean-reverting random walk approach used for recdevs
      for(i=1;i<=N_parm_dev;i++)
      {
        if(parm_dev_PH(i)>0 && parm_dev_lambda(k_phase)>0.0)
        {
          if(parm_dev_type(i)==1)  //  parameter dev
          {
            dvariable temp;
//        temp=1.00 / (2.000*(1.0-parm_dev_rho(i)*parm_dev_rho(i))*square(parm_dev_stddev(i)));
            temp=1.00 / (2.000*(1.0-parm_dev_rho(i)*parm_dev_rho(i))*square(1.00));

            parm_dev_like(i,1) += square( parm_dev(i,parm_dev_minyr(i)));  //  first year
            for(j=parm_dev_minyr(i)+1;j<=parm_dev_maxyr(i);j++)
            {parm_dev_like(i,1) += square( parm_dev(i,j)-parm_dev_rho(i)*parm_dev(i,j-1) );}
            parm_dev_like(i,1) *=temp;
            parm_dev_like(i,2) += float(parm_dev_maxyr(i)-parm_dev_minyr(i)+1.)*log(parm_dev_stddev(i));
            //  include parm_dev_like(i,2) in the total, or not, using sd_offset
          }
          else  //  2D_AR devs
          {
            f=parm_dev_info(i);  //  pointer from list of devvectors to 2DAR list
            dvariable sigmasel=selparm(TwoD_AR_def[f](13));
            parm_dev_stddev(i)=sigmasel;
            parm_dev_rho(i)=0.0;
//            echoinput<<" sigmasel "<<sigmasel<<endl;
            parm_dev_like(i,1)-=-0.5*log(det_cor(f));
            if(TwoD_AR_def[f](6)==TwoD_AR_def[f](4))  //  only one sigmasel by age
            {
//  nll -= - 0.5*log(det(cor)) - 0.5*nages*nyears*log(2.0*PI ) - 0.5*S_hat_vec*inv(cor)*S_hat_vec/pow(sigmaS,2) - 0.5*2*nages*nyears*log(sigmaS);
               if(TwoD_AR_def[f](7)==0)  // do not use rho
               {
                 parm_dev_like(i,1)-=  - 0.5*TwoD_AR_degfree(f)*log(2.0*PI ) - 0.5*sumsq(parm_dev(i))/pow(sigmasel,2);
                 parm_dev_like(i,2)-=  - TwoD_AR_degfree(f)*log(sigmasel);
               }
               else
               {
                 parm_dev_like(i,1)-=  - 0.5*TwoD_AR_degfree(f)*log(2.0*PI ) - 0.5*parm_dev(i)*inv_cor(f)*parm_dev(i)/pow(sigmasel,2);
                 parm_dev_like(i,2)-=  - TwoD_AR_degfree(f)*log(sigmasel);
               }
            }
            else  //  some age-specific sigmasel
            {
//  nll -= - 0.5*log(det(cor)) - 0.5*nages*nyears*log(2.0*PI ) - 0.5*S_hat_vec*inv(cor)*S_hat_vec/pow(sigmaS,2) - 0.5*2*nages*nyears*log(sigmaS);
            }
          }
        }
      }
    }

    for (f=1;f<=Nfleet;f++)
      if(Q_setup(f,4)==3)
      {
//      parm_dev_like += Q_dev_like(f,1); // mean component for dev approach (var component is already in the parm priors)
                                        //  do not include for randwalk (Qsetup==4)
      }

  //  SS_Label_Info_25.16 #Penalty for F_ballpark
    if(F_ballpark_yr>=styr)
      {
        if(F_Method==1)
        {temp=annual_F(F_ballpark_yr,1);}
        else
        {temp=annual_F(F_ballpark_yr,2);}
//  in future, could allow specification of a range of years for averaging the F statistic
        F_ballpark_like = 0.5*square( log((F_ballpark+1.0e-6)/(temp+1.0e-6)) / 1.0) + sd_offset*log(1.0);
      }
    else
      {F_ballpark_like=0.0;}

  //  SS_Label_Info_25.17 #Penalty for soft boundaries, uses the symmetric beta prior code
  if(SoftBound>0)
  {
    SoftBoundPen=0.0;

      for (i=1;i<=N_selparm2;i++)
      if(active(selparm(i)))
        {SoftBoundPen+=Get_Prior(1, selparm_LO(i), selparm_HI(i), 1., 0.001, selparm(i));}
  }


  //  SS_Label_Info_25.18 #Crash penalty
//   CrashPen = square(1.0+CrashPen)-1.0;   this was used until V3.00L  7/10/2008
     CrashPen = square(1.0+ (1000.*CrashPen/(1000.+CrashPen)))-1.0;
  //  SS_Label_Info_25.19 #Sum the likelihood components weighted by lambda factors
//   cout<<" obj_fun start "<<obj_fun<<endl;
   obj_fun = column(surv_lambda,k_phase)*surv_like;
//   cout<<" obj_fun surv "<<obj_fun<<surv_like<<endl;
   obj_fun += column(disc_lambda,k_phase)*disc_like;
//   cout<<" obj_fun disc "<<obj_fun<<endl;
   obj_fun += column(mnwt_lambda,k_phase)*mnwt_like;
//   cout<<" obj_fun mnwt "<<obj_fun<<endl;
   obj_fun += column(length_lambda,k_phase)*length_like_tot;
//   cout<<" obj_fun len "<<obj_fun<<endl;
   obj_fun += column(age_lambda,k_phase)*age_like_tot;
//   cout<<" obj_fun age "<<obj_fun<<endl;
   obj_fun += column(sizeage_lambda,k_phase)*sizeage_like;
//   cout<<" obj_fun ms "<<obj_fun<<endl;

   obj_fun += equ_catch_like*init_equ_lambda(k_phase);
//   cout<<" obj_fun equ_cat "<<obj_fun<<endl;
   obj_fun += column(catch_lambda,k_phase)*catch_like;
//            catch_like(f) += 0.5*square( (log(1.1*catch_ret_obs(f,t)) -log(catch_fleet(t,f,i)*catch_mult(y,f)+0.1*catch_ret_obs(f,t))) / catch_se(t,f));
//   cout<<" obj_fun catch "<<obj_fun<<catch_like<<endl;
   obj_fun += recr_like*recrdev_lambda(k_phase);
//   cout<<" obj_fun recr "<<obj_fun<<endl;
   obj_fun += parm_like*parm_prior_lambda(k_phase);
//   cout<<" obj_fun parm "<<obj_fun<<endl;
   obj_fun += (sum(parm_dev_like))*parm_dev_lambda(k_phase);
//   cout<<" obj_fun parmdev "<<obj_fun<<endl;
   obj_fun += F_ballpark_like * F_ballpark_lambda(k_phase);
//   cout<<" obj_fun Fballpark "<<obj_fun<<endl;
   obj_fun += CrashPen_lambda(k_phase)*CrashPen;
//   cout<<" obj_fun crash "<<obj_fun<<endl;
   obj_fun += square(dummy_datum-dummy_parm);
//   cout<<" obj_fun dummy "<<obj_fun<<endl;
   obj_fun += Fcast_recr_like;  //  lambda already factored in
//   cout<<" obj_fun forerecr "<<obj_fun<<endl;
   obj_fun += SoftBoundPen;
//   cout<<" obj_fun soft "<<obj_fun<<endl;
   if(SzFreq_Nmeth>0)  obj_fun += SzFreq_like*column(SzFreq_lambda,k_phase);
//   cout<<" obj_fun sizefreq "<<obj_fun<<endl;
   if(Do_Morphcomp>0) obj_fun += Morphcomp_lambda(k_phase)*Morphcomp_like;
   if(Do_TG>0 && Nfleet>1) obj_fun += TG_like1*column(TG_lambda1,k_phase);
   if(Do_TG>0) obj_fun += TG_like2*column(TG_lambda2,k_phase);
//   cout<<" obj_fun final "<<obj_fun<<endl;
  }  //  end objective_function

//********************************************************************
 /*  SS_Label_FUNCTION 26 Process_STDquant */
FUNCTION void Process_STDquant()
  {
      for (y=styr-2; y<=YrMax;y++)
      {
        if(STD_Yr_Reverse(y)>0)
        {
          SPB_std(STD_Yr_Reverse(y))=SPB_yr(y);
          recr_std(STD_Yr_Reverse(y))=exp_rec(y,4);
        }
        if(STD_Yr_Reverse_Dep(y)>0) {depletion(STD_Yr_Reverse_Dep(y))=SPB_yr(y);}
      }

      switch(depletion_basis)
      {
        case 0:
        {
          depletion/=SPB_virgin;
          break;
        }
        case 1:
        {
          depletion/= (depletion_level*SPB_virgin);
          break;
        }
        case 2:
        {
          depletion/= (depletion_level*Bmsy);
          break;
        }
        case 3:
        {
          depletion/= (depletion_level*SPB_yr(styr));
          break;
        }
      }

      switch (SPR_reporting)
      {
        case 0:      // keep as raw value
        {
          break;
        }
        case 1:  // compare to SPR
        {
//          SPR_std = (1.-SPR_std)/(1.-SPR_actual);
          SPR_std = (1.-SPR_std)/(1.-SPR_target);
          break;
        }
        case 2:  // compare to SPR_MSY
        {
          SPR_std = (1.-SPR_std)/(1.-MSY_SPR);
          break;
        }
        case 3:  // compare to SPR_Btarget
        {
          SPR_std = (1.-SPR_std)/(1.-SPR_Btgt);
          break;
        }
        case 4:
        {
          SPR_std = 1.-SPR_std;
          break;
        }
      }

//  init_int Do_Forecast   //  0=none; 1=F(SPR); 2=F(MSY) 3=F(Btgt); 4=F(endyr); 5=Ave F (enter yrs); 6=read Fmult
//  Use the selected F method for the forecast as the denominator for the F_std ratio
      switch (F_std_basis)
      {
        case 0:      // keep as raw value
        {
          break;
        }
        case 1:  // compare to SPR
        {
          F_std /= Mgmt_quant(10);
          break;
        }
        case 2:  // compare to SPR_MSY
        {
          F_std /= Mgmt_quant(14);
          break;
        }
        case 3:  // compare to SPR_Btarget
        {
          F_std /= Mgmt_quant(7);
          break;
        }
      }
//  SS_Label_7.8  get extra std quantities
    if(Selex_Std_Cnt>0)
    {
      for (i=1;i<=Selex_Std_Cnt;i++)
      {
        j=Selex_Std_Pick(i);
        if(Selex_Std_AL==1)
        {
          Extra_Std(i)=sel_l(Selex_Std_Year,Do_Selex_Std,1,j);
          if(gender==2) Extra_Std(i+Selex_Std_Cnt)=sel_l(Selex_Std_Year,Do_Selex_Std,2,j);
        }
        else
        {
          Extra_Std(i)=sel_a(Selex_Std_Year,Do_Selex_Std,1,j);
          if(gender==2) Extra_Std(i+Selex_Std_Cnt)=sel_a(Selex_Std_Year,Do_Selex_Std,2,j);
        }
      }
    }

    if(Growth_Std_Cnt>0)
    {
      for (i=1;i<=Growth_Std_Cnt;i++)
      {
        j=Growth_Std_Pick(i);  // selected age
        k=g_finder(Do_Growth_Std,1);  // selected GP and gender  gp3
        Extra_Std(gender*Selex_Std_Cnt+i)=Ave_Size(t,mid_subseas,k,j);
        if(gender==2)
        {
          k=g_finder(Do_Growth_Std,2);  // selected GP and gender  gp3
          Extra_Std(gender*Selex_Std_Cnt+Growth_Std_Cnt+i)=Ave_Size(t,mid_subseas,k,j);
        }
      }
    }

    if(NatAge_Std_Cnt>0)
    {
      if(Do_NatAge_Std<0)  // sum all areas
      {
        p1=1; p2=pop;
      }
      else  // selected area
      {
        p1=Do_NatAge_Std; p2=Do_NatAge_Std;
      }
      y=NatAge_Std_Year;
      t=styr+(y-styr)*nseas;  // first season of selected year
      for (i=1;i<=NatAge_Std_Cnt;i++)
      {
        a=NatAge_Std_Pick(i);  // selected age
        temp=0.;
        for (p=p1;p<=p2;p++)
        {
          for (g=1;g<=gmorph;g++)
          if(sx(g)==1 && use_morph(g)>0)
          {
            temp+=natage(t,p,g,a);  //  note, uses season 1 only
          }
        }
        Extra_Std(gender*(Selex_Std_Cnt+Growth_Std_Cnt)+i)=temp;
        if(gender==2)
        {
          temp=0.;
          for (p=p1;p<=p2;p++)
          {
            for (g=1;g<=gmorph;g++)
            if(sx(g)==2 && use_morph(g)>0)
            {
              temp+=natage(t,p,g,a);  //  note, uses season 1 only
            }
          }
          Extra_Std(gender*(Selex_Std_Cnt+Growth_Std_Cnt)+NatAge_Std_Cnt+i)=temp;
        }
      }
    }

    if(Extra_Std_N==1)
    {
      Extra_Std(1)=SPB_virgin;
    }

    if(Svy_N>0)
    {
      int Svy_sdreport_counter = 1;
      for (f=1;f<=Nfleet;f++)
      {
        if (Svy_sdreport(f) > 0)
        {
          for (i=1;i<=Svy_N_fleet(f);i++)
          {
            Svy_sdreport_est(Svy_sdreport_counter) = Svy_est(f,i);
            ++Svy_sdreport_counter;
          }
        }
      }
    }

  }

//********************************************************************
 /*  SS_Label_FUNCTION 27 Check_Parm */
FUNCTION dvariable Check_Parm(const int iparm, const int& PrPH, const double& Pmin, const double& Pmax, const int& Prtype, const double& Pr, const double& Psd, const double& jitter, const prevariable& Pval)
  {
    const dvariable zmin = inv_cumd_norm(0.001);    // z value for Pmin
    const dvariable zmax = inv_cumd_norm(0.999);    // z value for Pmax
    const dvariable Pmean = (Pmin + Pmax) / 2.0;
    dvariable NewVal;
    // dvariable temp;
    dvariable Psigma, zval, kval, kjitter, zjitter;

    NewVal=Pval;
    if(Pmin>Pmax)
    {N_warn++; cout<<" EXIT - see warning "<<endl; warning<<" parameter min > parameter max "<<Pmin<<" > "<<Pmax<<" for parm: "<<iparm<<endl; cout<<" fatal error, see warning"<<endl; exit(1);}
    if(Pmin==Pmax && PrPH>=0)
    {N_warn++; warning<<" parameter min is same as parameter max"<<Pmin<<" = "<<Pmax<<" for parm: "<<iparm<<endl;}
    if(Pval<Pmin && PrPH>=0)
    {N_warn++; warning<<" parameter init value is less than parameter min "<<Pval<<" < "<<Pmin<<" for parm: "<<iparm<<endl; NewVal=Pmin;}
    if(Pval>Pmax && PrPH>=0)
    {N_warn++; warning<<" parameter init value is greater than parameter max "<<Pval<<" > "<<Pmax<<" for parm: "<<iparm<<endl; NewVal=Pmax;}
    if(jitter>0.0 && PrPH>=0)
    {
      // temp=log((Pmax-Pmin+0.0000002)/(NewVal-Pmin+0.0000001)-1.)/(-2.);   // transform the parameter
      // temp += randn(radm) * jitter;
      // NewVal=Pmin+(Pmax-Pmin)/(1.+mfexp(-2.*temp));

      // generate jitter value from cumulative normal given Pmin and Pmax
      Psigma = (Pmax - Pmean) / zmax;   // Psigma should also be equal to (Pmin - Pmean) / zmin;
      if (Psigma < 0.00001)    // how small a sigma is too small?
      {
          N_warn++;
          cout<<" EXIT - see warning "<<endl;
          warning<<" in Check_Parm jitter:  Psigma < 0.00001 "<<Psigma<<endl;
          cout<<" fatal error, see warning"<<endl; exit(1);
      }
      zval = (Pval - Pmean) / Psigma;
      kval = cumd_norm(zval);
      kjitter = kval + (jitter * ((2.0 * randu(radm)) - 1.0));  // kjitter is between kval - jitter and kval + jitter
      if (kjitter < 0.001)
      {
          zjitter = zmin;
      }
      else if (kjitter > 0.999)
      {
          zjitter = zmax;
      }
      else
      {
          zjitter = inv_cumd_norm(kjitter);
      }
      NewVal = (Psigma * zjitter) + Pmean;

      if(Pmin==-99 || Pmax==99)
      {N_warn++; warning<<" use of jitter not advised unless parameter min & max are in reasonable parameter range "<<Pmin<<" "<<Pmax<<endl;}
    }
    //  now check prior
    if(Prtype>0)
    {
      if(Psd<=0.0) {N_warn++; cout<<"fatal error in prior check, see warning"<<endl; warning<<"FATAL:  A prior is selected but prior sd is zero. Prtype: "<<Prtype<<" Prior: "<<Pr<<" Pr_sd: "<<Psd<<" for parm: "<<iparm<<endl; exit(1);}
    }

    return NewVal;
  }

//********************************************************************
 /*  SS_Label_FUNCTION 29 Get_Prior */
FUNCTION dvariable Get_Prior(const int T, const double& Pmin, const double& Pmax, const double& Pr, const double& Psd, const prevariable& Pval)
  {
    dvariable Prior_Like=0.;
    dvariable mu;
    dvariable tau;
    dvariable Pconst=0.0001;
    dvariable Bprior;
    dvariable Aprior;
    switch (T)
    {
      case 0:  // none
      {
        Prior_Like = 0.;
        break;
      }
      case 6: // normal
      {
        Prior_Like = 0.5*square((Pval-Pr)/Psd);
        break;
      }
      case 1:  // symmetric beta    value of Psd must be >0.0
      {
        mu=-(Psd*(log( (Pmax+Pmin)*0.5- Pmin)))- (Psd*(log(0.5)));
        Prior_Like = -(mu+ (Psd*(log(Pval-Pmin+Pconst)))+(Psd*(log(1.-((Pval-Pmin-Pconst)/(Pmax-Pmin))))));
        break;
      }
      case 2:  // CASAL's Beta;  check to be sure that Aprior and Bprior are OK before running SS2!
      {
        mu=(Pr-Pmin) / (Pmax-Pmin);  // CASAL's v
        tau=(Pr-Pmin)*(Pmax-Pr)/square(Psd)-1.0;
        Bprior=tau*mu;  Aprior=tau*(1.0-mu);  // CASAL's m and n
        if(Bprior<=1.0 || Aprior <=1.0) {warning<<" bad Beta prior "<<Pval<<" "<<Pr<<endl;N_warn++;}
        Prior_Like =  (1.0-Bprior)*log(Pconst+Pval-Pmin) + (1.0-Aprior)*log(Pconst+Pmax-Pval)
              -(1.0-Bprior)*log(Pconst+Pr-Pmin) - (1.0-Aprior)*log(Pconst+Pmax-Pr);
        break;
      }
      case 3: // lognormal without bias correction
      {
        if(Pmin>0.0) {Prior_Like = 0.5*square((log(Pval)-Pr)/Psd);}
          else {N_warn++; warning<<" cannot do prior in log space for parm with min <=0.0" << endl;}
        break;
      }
      case 4: //lognormal with bias correction (from Larry Jacobson)
      {
        if(Pmin>0.0) Prior_Like=0.5*square((log(Pval)-Pr+0.5*square(Psd))/Psd);
          else {N_warn++; warning<<" cannot do prior in log space for parm with min <=0.0" << endl;}
        break;
      }
      case 5: //gamma  (from Larry Jacobson)
      {
        double warnif=1e-15;
        if(Pmin<0.0) {N_warn++; warning<<"Lower bound for gamma prior must be >=0.  Suggestion " << warnif*10.0 <<endl;}
        else
        {
//Gamma is defined over [0,+inf) but x=zero causes trouble for some mean/variance combos.
          if(Pval < warnif) {N_warn++; warning<<"Pval too close to zero in gamma prior - can not guarantee reliable calculations.  Suggest rescaling data (e.g. * 1000)? "<<endl;}
          else
          {
            dvariable scale=square(Psd)/Pr;  // gamma parameters by method of moments
            dvariable shape=Pr/scale;
            Prior_Like= -shape*log(scale)-gammln(shape)+(shape-1.0)*log(Pval)-Pval/scale;
          }
        }
        break;
      }
    }
    return Prior_Like;
  }

FUNCTION void get_posteriors()
  {
//********************************************************************
 /*  SS_Label_FUNCTION 33 get_posteriors  (MCMC eval) */
  if(rundetail>1) cout<<" mceval counter: "<<mceval_counter<<endl;
  if(rundetail==0 & double(mceval_counter)/200.==double(mceval_counter/200.)) cout<<" mceval counter: "<<mceval_counter<<endl;

  if(mceval_header==0 && mceval_phase())    // first pass through the mceval phase
  {
    // delete any old mcmc output files
    // will generate a warning if no files exist
    // but will play through just fine
    // NOTE:  "del" works on Windows only; use "rm" on other operating systems
    system("del rebuild.sso");
    system("del posteriors.sso");
    system("del derived_posteriors.sso");
    system("del posterior_vectors.sso");
    system("del posterior_obj_func.sso");
    if(rundetail>0) cout<<" did system commands "<<endl;
  };
  // define the mcmc output files;
  ofstream rebuilder("rebuild.sso",ios::app);
  ofstream posts("posteriors.sso",ios::app);
  ofstream der_posts("derived_posteriors.sso",ios::app);
  ofstream post_vecs("posterior_vectors.sso",ios::app);
  ofstream post_obj_func("posterior_obj_func.sso",ios::app);

  if(mceval_header==0)    // first pass through the mceval phase
  {
    mceval_header=1;
    // produce the appropriate headers for the posteriors.rep
    // and derived_posteriors.rep files
    // parameters.rep matches "PARAMETERS" section in Report.SSO file
    if(rundetail>0) cout<<" write mcmc headers "<<endl;
    posts<<"Iter Objective_function ";
    for (i=1;i<=active_count;i++) {posts<<" "<<ParmLabel(active_parm(i));}
    posts << endl;

    // derived quantities
    // derived_parameters.rep matches "DERIVED_PARAMETERS" section in Report.SSO file
    NP = ParCount;
    der_posts<<"Iter Objective_function ";
    for (j=1;j<=N_STD_Yr;j++) // spawning biomass
    {
      NP++;  der_posts<<ParmLabel(NP)<<" ";
    }
    for (j=1;j<=N_STD_Yr;j++) // recruitment
    {
      NP++;  der_posts<<ParmLabel(NP)<<" ";
    }
    for (j=1;j<=N_STD_Yr_Ofish;j++) // SPRratio
    {
      NP++;  der_posts<<ParmLabel(NP)<<" ";
    }
    for (j=1;j<=N_STD_Yr_F;j++) // F
    {
      NP++;  der_posts<<ParmLabel(NP)<<" ";
    }
    for (j=1;j<=N_STD_Yr_Dep;j++) // depletion (Bratio)
    {
      NP++;  der_posts<<ParmLabel(NP)<<" ";
    }
    for (j=1;j<=N_STD_Mgmt_Quant;j++) // Management quantities
    {
      NP++;  der_posts<<ParmLabel(NP)<<" ";
    }
    for (j=1;j<=Extra_Std_N;j++)
    {
      NP++;  der_posts<<ParmLabel(NP)<<" ";
    }
    der_posts << endl;

    if(depletion_basis!=2) post_vecs<<"depletion_basis_is_not_=2;_so_info_below_is_not_B/Bmsy"<<endl;
    if(F_std_basis!=2) post_vecs<<"F_std_basis_is_not_=2;_so_info_below_is_not_F/Fmsy"<<endl;
    post_vecs<<"Endyr+1= "<<endyr+1<<endl;
    post_vecs<<"run mceval objfun Numbers Area Sex Ages:"<<age_vector<<endl;
    post_vecs<<"run mceval objfun F_yr ";
    for (y=styr-1;y<=YrMax; y++)
    {
      if(STD_Yr_Reverse_F(y)>0) post_vecs<<y<<" ";
    }
    post_vecs<<endl;
    post_vecs<<"run mceval objfun B_yr ";
    for (y=styr-1;y<=YrMax; y++)
    {
      if(STD_Yr_Reverse_Dep(y)>0) post_vecs<<y<<" ";
    }
    post_vecs<<endl;

    if (mcmc_output_detail > 0)
    {
        std::stringstream iter_labels;
        std::stringstream lambda_labels;

        iter_labels   << "Iter | Objective_function";
        lambda_labels << "---- | Lambdas";

        if(F_Method>1)
        {
            iter_labels   << " | Catch";
            lambda_labels << " | " << column(catch_lambda,max_lambda_phase);
        }

        iter_labels   << " | Equil_catch";
        lambda_labels << " | " << init_equ_lambda(max_lambda_phase);

        if(Svy_N>0)
        {
            iter_labels   << " | Survey";
            lambda_labels << " | " << column(surv_lambda,max_lambda_phase);
        }
        if(nobs_disc>0)
        {
            iter_labels   << " | Discard";
            lambda_labels << " | " << column(disc_lambda,max_lambda_phase);
        }
        if(nobs_mnwt>0)
        {
            iter_labels   << " | Mean_body_wt";
            lambda_labels << " | " << column(mnwt_lambda,max_lambda_phase);
        }
        if(Nobs_l_tot>0)
        {
            iter_labels   << " | Length_comp";
            lambda_labels << " | " << column(length_lambda,max_lambda_phase);
        }
        if(Nobs_a_tot>0)
        {
            iter_labels   << " | Age_comp";
            lambda_labels << " | " << column(age_lambda,max_lambda_phase);
        }
        if(nobs_ms_tot>0)
        {
            iter_labels   << " | Size_at_age";
            lambda_labels << " | " << column(sizeage_lambda,max_lambda_phase);
        }
        if(SzFreq_Nmeth>0)
        {
            iter_labels   << " | SizeFreq";
            lambda_labels << " | " << column(SzFreq_lambda,max_lambda_phase);
        }
        if(Do_Morphcomp>0)
        {
            iter_labels   << " | Morphcomp";
            lambda_labels << " | " << Morphcomp_lambda(max_lambda_phase);
        }
        if(Do_TG>0)
        {
            iter_labels   << " | Tag_comp | Tag_negbin";
            lambda_labels << " | " << column(TG_lambda1,max_lambda_phase) << " | " << column(TG_lambda2,max_lambda_phase);
        }

        iter_labels   << " | Recruitment";
        lambda_labels << " | " << recrdev_lambda(max_lambda_phase);

        iter_labels   << " | Forecast_Recruitment";
        lambda_labels << " | " << Fcast_recr_lambda;

        iter_labels   << " | Parm_priors";
        lambda_labels << " | " << parm_prior_lambda(max_lambda_phase);

        if(SoftBound>0)
        {
            iter_labels   << " | Parm_softbounds";
            lambda_labels << " | NA";
        }

        iter_labels   << " | Parm_devs";
        lambda_labels << " | " << parm_dev_lambda(max_lambda_phase);

        if(F_ballpark_yr>0)
        {
            iter_labels   << " | F_Ballpark";
            lambda_labels << " | " << F_ballpark_lambda(max_lambda_phase);
        }

        iter_labels   << " | Crash_Pen ";
        lambda_labels << " | " << CrashPen_lambda(max_lambda_phase);

        post_obj_func << iter_labels.str() << endl;
        post_obj_func << lambda_labels.str() << endl;
    }
  };  //  end writing headers for mceval_counter==1


  // produce standard output of all estimated parameters
  posts<<mceval_counter<<" "<<obj_fun<<" ";

  for (j=1;j<=N_MGparm2;j++)
  {
    if(active(MGparm(j))) posts<<MGparm(j)<<" ";
  }
  for (i=1;i<=N_SRparm3;i++)
  {
    if(active(SR_parm(i))) posts<<SR_parm(i)<<" ";
  }

  if(recdev_cycle>0)
  {
    for (i=1;i<=recdev_cycle;i++)
    {
      if(active(recdev_cycle_parm(i))) posts<<recdev_cycle_parm(i)<<" ";
    }
  }
  if(recdev_do_early>0)
  {
    for (i=recdev_early_start;i<=recdev_early_end;i++)
    {
      if( active(recdev_early) ) posts<<recdev(i)<<" ";
    }
  }
  if(do_recdev>0)
  {
    for (i=recdev_start;i<=recdev_end;i++)
    {
      if( active(recdev1)||active(recdev2) ) posts<<recdev(i)<<" ";
    }
  }
  if(Do_Forecast>0)
  {
    for (i=recdev_end+1;i<=YrMax;i++)
    {
      if(active(Fcast_recruitments)) posts<<Fcast_recruitments(i)<<" ";
    }
    for (i=endyr+1;i<=YrMax;i++)
    {
      if(active(Fcast_impl_error)) posts<<Fcast_impl_error(i)<<" ";
    }
  }
  for (i=1;i<=N_init_F;i++)
  {
    if(active(init_F(i))) posts<<init_F(i)<<" ";
  }
  if(F_Method==2)
  {
    for (i=1;i<=N_Fparm;i++)
    {
      if(active(F_rate(i))) posts<<F_rate(i)<<" ";
    }
  }
  for (i=1;i<=Q_Npar;i++)
  {
    if(active(Q_parm(i)))posts<<Q_parm(i)<<" ";
  }
  for (j=1;j<=N_selparm2;j++)
  {
    if(active(selparm(j))) posts<<selparm(j)<<" ";
  }
  if(Do_TG>0)
  {
    k=3*N_TG+2*Nfleet1;
    for (j=1;j<=k;j++)
    {
      if(active(TG_parm(j))) posts<<TG_parm(j)<<" ";
    }
  }
  if(N_parm_dev>0)
  {
    for (i=1;i<=N_parm_dev;i++)
    for (j=parm_dev_minyr(i);j<=parm_dev_maxyr(i);j++)
    {
      if(parm_dev_PH(i)>0) posts<<parm_dev(i,j)<<" ";
    }
  }
  posts << endl;

  // derived quantities
  der_posts<<mceval_counter<<" "<<obj_fun<<" ";
  for (j=1;j<=N_STD_Yr;j++) // spawning biomass
  {
    der_posts<<SPB_std(j)<<" ";
  }
  for (j=1;j<=N_STD_Yr;j++) // recruitment
  {
    der_posts<<recr_std(j)<<" ";
  }
  for (j=1;j<=N_STD_Yr_Ofish;j++) // SPRratio
  {
    der_posts<<SPR_std(j)<<" ";
  }
  for (j=1;j<=N_STD_Yr_F;j++) // F
  {
    der_posts<<F_std(j)<<" ";
  }
  for (j=1;j<=N_STD_Yr_Dep;j++) // depletion (Bratio)
  {
    der_posts<<depletion(j)<<" ";
  }
  for (j=1;j<=N_STD_Mgmt_Quant;j++) // Management quantities
  {
    der_posts<<Mgmt_quant(j)<<" ";
  }
  for (j=1;j<=Extra_Std_N;j++)
  {
    der_posts<<Extra_Std(j)<<" ";
  }

  der_posts << endl;

  if(Do_Rebuilder>0) write_rebuilder_output();

  // derived vectors quantities
  t=styr+(endyr+1-styr)*nseas;
  for (p=1;p<=pop;p++)
  {
    for (gg=1;gg<=gender;gg++)
    {
      tempvec_a.initialize();
      for (g=1;g<=gmorph;g++)
      if(sx(g)==gg && use_morph(g)>0)
      {
        tempvec_a+=natage(t,p,g);
      }
      post_vecs<<runnumber<<" "<<mceval_counter<<" "<<obj_fun<<" N_at_Age "<<" "<<p<<" "<<gg<<" "<<tempvec_a<<endl;
    }
  }
  post_vecs<<runnumber<<" "<<mceval_counter<<" "<<obj_fun<<" F/Fmsy "<<F_std<<endl;
  post_vecs<<runnumber<<" "<<mceval_counter<<" "<<obj_fun<<" B/Bmsy "<<depletion<<endl;

  // output objective function components
  if (mcmc_output_detail > 0)
  {
      post_obj_func<<mceval_counter<<" | "<<obj_fun;

      if(F_Method>1) post_obj_func << " | " << catch_like;
      post_obj_func << " | " << equ_catch_like;
      if(Svy_N>0) post_obj_func << " | " << surv_like;
      if(nobs_disc>0) post_obj_func << " | " << disc_like;
      if(nobs_mnwt>0) post_obj_func << " | " << mnwt_like;
      if(Nobs_l_tot>0) post_obj_func << " | " << length_like_tot;
      if(Nobs_a_tot>0) post_obj_func << " | " << age_like_tot;
      if(nobs_ms_tot>0) post_obj_func << " | " << sizeage_like;
      if(SzFreq_Nmeth>0) post_obj_func << " | " << SzFreq_like;
      if(Do_Morphcomp>0) post_obj_func << " | " << Morphcomp_like;
      if(Do_TG>0) post_obj_func << " | " << TG_like1 << " | " << TG_like2;
      post_obj_func << " | " << recr_like;
      post_obj_func << " | " << Fcast_recr_like;
      post_obj_func << " | " << parm_like;
      if(SoftBound>0) post_obj_func << " | " << SoftBoundPen;
      post_obj_func << " | " << (sum(parm_dev_like));
      if(F_ballpark_yr>0) post_obj_func << " | " << F_ballpark_like;
      post_obj_func << " | " << CrashPen;

      post_obj_func<<endl;
  }

  }  //  end get_posteriors

