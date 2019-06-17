
%macro attrv(ds,var,attrib);
  %local dsid rc varnum err;
  %let err=ERR%str(OR);
  %let dsid=%sysfunc(open(&ds,is));
  %if &dsid EQ 0 %then %do;
    %put &err: (attrv) Dataset &ds not opened due to the following reason:;
    %put %sysfunc(sysmsg());
  %end;
  %else %do;
    %let varnum=%sysfunc(varnum(&dsid,&var));
    %if &varnum LT 1 %then %put &err: (attrv) Variable &var not in dataset &ds;
    %else %do;
%sysfunc(&attrib(&dsid,&varnum))
    %end;
    %let rc=%sysfunc(close(&dsid));
  %end;
%mend attrv;

%macro varlabel(ds,var);
  %attrv(&ds,&var,varlabel)
%mend varlabel;


%macro vartype(ds,var);
  %attrv(&ds,&var,vartype)
%mend vartype;

%macro words(str,delim=%str( ));
  %local i;
  %let i=1;
  %do %while(%length(%qscan(&str,&i,&delim)) GT 0);
    %let i=%eval(&i + 1);
  %end;
%eval(&i - 1)
%mend words;


%macro quotelst(str,quote=%str(%"),delim=%str( ));
  %local i quotelst;
  %let i=1;
  %do %while(%length(%qscan(&str,&i,%str( ))) GT 0);
    %if %length(&quotelst) EQ 0 %then %let quotelst=&quote.%qscan(&str,&i,%str( ))&quote;
    %else %let quotelst=&quotelst.&quote.%qscan(&str,&i,%str( ))&quote;
    %let i=%eval(&i + 1);
    %if %length(%qscan(&str,&i,%str( ))) GT 0 %then %let quotelst=&quotelst.&delim;
  %end;
%unquote(&quotelst)
%mend quotelst;



/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/



%macro init();

filename general temp mod;
filename datajs temp mod;
filename plots temp mod;
filename resetall temp mod;
filename filters temp mod;
filename onselect temp mod;



%mend;



%macro data(dset);
filename &dset temp mod;

proc sql noprint;

select catx('=',name,lowcase(name)) into : names separated by ' '

  from dictionary.columns

    where libname='WORK' and memname="%upcase(&dset)";

quit;

proc datasets lib=work nolist;

modify &dset ;

rename &names;

run;

quit;

Proc json out=&dset  pretty;

export &dset / keys nosastags;
run;
quit;



proc stream outfile=datajs resetdelim='dosas'; begin
<script>
&dset.obj = 
dosas readfile &dset.;
</script>

<script>
    &dset.cf = crossfilter(&dset.obj);
</script>


;;;;
RUN;

%mend;


%macro compile(htmlout=,title=);

filename htmlout "&htmlout";

proc stream outfile=htmlout resetdelim='dosas'; begin
<html>

<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>&title</title>



  <script src="https://cdnjs.cloudflare.com/ajax/libs/crossfilter2/1.4.6/crossfilter.js"></script>
  <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>

  <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css" rel="stylesheet">

  <style>
    @import 'https://fonts.googleapis.com/css?family=Rubik:300,400,500,700,900';

    body {
      background: #edf1f5;
      font-family: Rubik, sans-serif;
      margin: 0;
      overflow-x: hidden;
      color: #686868;
      font-weight: 300
    }

    html {
      position: relative;
      min-height: 100%;
      background: #fff
    }

    .bg-title {
      background: #fff;
      padding: 15px 15px 10px;
      margin-bottom: 25px;
      margin-left: -25.5px;
      margin-right: -25.5px;
    }

    .white-box {
      background: #fff;
      padding: 25px;
      margin-bottom: 15px;
    }

    h4 {
      line-height: 22px;
      font-size: 14px;
    }

    h3 {
      font-size: 12px;
      font-weight: 500;
    }


    .sidebar {
      overflow-y: auto;
      z-index: 10;
      position: absolute;
      width: 220px;
      padding-top: 60px;
      height: 100%;
      background: #516673;
      box-shadow: 1px 0 20px rgba(0, 0, 0, 0.08);
    }


    .nav {
      padding-left: 0;
      margin-bottom: 0;
      list-style: none;
    }

    #page-wrapper {
      position: inherit;
      margin: 0 0 0 220px;
    }


    label {
      color: #fff;
    }

    .form-group {
      margin: 10px 0 0 10px;
    }
  </style>


dosas readfile datajs;

dosas readfile general;


<script>


    function onselect(dim, source) {
dosas readfile onselect;
}

</script>

<script>


    function resetall() {
    dosas readfile resetall;	
	}

</script>


</head>
<body>

  <div id="wrapper">

    <div class="sidebar">

dosas readfile filters;        		
        		
    </div> /*sidebar*/

		<div id="page-wrapper">
			<div class="container-fluid">
				
				/*page-title*/
				<div class="row bg-title">
          			<div class="col-lg-3">
            			<h4 class="page-title">&title</h4>
          			</div>
        		</div>
        		/*page-title*/


dosas readfile plots;      		
        		
			</div> /*container-fluid*/
		</div> /*page-wrapper*/
  </div> /*wrapper*/
</body>
</html>
;;;;
RUN;
QUIT;

%mend;





%macro filters(data=,vars=);
%let vars = %lowcase(&vars);

proc stream outfile=general resetdelim="dosas"; begin
 <script>
    function getOptions(div, cf, variable) {

      let optiondim = cf.dimension((d) => d[variable]);
      const optpoints = optiondim.top(Infinity);
      const optarray = optpoints.map(function (d) {
          return d[variable]
        })
        .filter((v, i, a) => a.indexOf(v) === i);

        optarray.sort();

        let e = '';
      for (val of optarray) {
        e += `<option value=${val}>${val}</option>`;

      }

      document.getElementById(div).innerHTML = e;
    }
  </script>

;;;;
run;
quit;






%do w = 1 %to %words(&vars);

%let var = %qscan(&vars,&w) ;
%let varlabel = %varlabel(&data.,&var.);

proc stream outfile=filters resetdelim='dosas'; begin





      <div class="form-group">
        <label for="&var.select"> &varlabel. (%upcase(&var.)) </label>
        <select multiple class="form-control col-md-10" id="&var.Select"></select>
      </div>

      <script>
        getOptions("&var.Select", &data.cf, "&var.");

        function &var.Listener(div, cf, variable) {
          let &var.dim = cf.dimension(function (d) {
            return d[variable]
          });
          document.getElementById(div).addEventListener('change', function (event) {

%if %vartype(&data.,&var.) = %str(N) %then %do;
            const optarray = Array.prototype.slice.call(this.selectedOptions, 0).map((d) => +d.innerText);
%end;
%else %do;
       const optarray = Array.prototype.slice.call(this.selectedOptions, 0).map((d) => d.innerText);
%end;

            if (event.target.value) {
              console.log(optarray);

              &var.dim.filterAll();

              &var.dim.filter(function (d) {
                return optarray.indexOf(d) != -1 ;
              });
              resetall();

            } else {
              &var.dim.filterAll();
              resetall();
            }

          });
        };

        &var.Listener("&var.Select", &data.cf, "&var");
      </script>



;;;;
run;
quit;
%end;
%mend;


/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

libname psug "C:\Users\boddur\OneDrive - Shire PLC\My Projects\PharmaSUG 2019\resources\data\sas from jmp";


data AE;
 set psug.AE_Incidence;
run;


options spool;
%init;

%data(AE);
%filters(data=AE,vars=AEBODSYS);

%scatter(name=ast,data=AE,x=RiskDiff,y=NegLog10_Raw_p,color=RR,size=Count,animation_frames=TimeWindowNum,ID=AEDECOD);


%compile(htmlout=C:\Users\boddur\Documents\GitHub\interactive-plots\sas\output\temp1.html,
title=AE Incidense);

