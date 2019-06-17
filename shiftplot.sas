
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


filename general temp ;
filename datajs temp ;
filename plots temp ;
filename resetall temp ;
filename filters temp ;
filename onselect temp ;


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

%macro scatter(name=,title=,data=,x=,y=,color=,shape=,animation_frames=,marginal=,hoverinfo=,hist=);


%let x = %lowcase(&x);
%let y = %lowcase(&y);
%let hoverinfo = %lowcase(&hoverinfo);
%let color= %lowcase(&color);


%if %symexist(nscatter) %then %do;

  %let nscatter = %eval(&nscatter + 1);

%end;

%else %do;



proc stream outfile=general resetdelim="dosas"; begin
 <script>


    function scatterpoints(cf, points) {
      let dim = cf.dimension(function (d) {
        return [d[points[0]], d[points[1]], d[points[2]]];
      });

      let scatterpoints = dim.top(Infinity);

      return scatterpoints;

      dim.filterAll();
      dim.dispose();


    }




function hovertext(d,hoverinfo) {

  let hovertext = "<br>";

if (hoverinfo) {
   hoverinfo.forEach(e => {
     hovertext += `${e}: ${d[e]}<br>`;
   });
}

return hovertext;

}




    function scatter(div, cf, points,hoverinfo,xtitle,ytitle) {
 





      let dim = cf.dimension(function (d) {
        return [d[points[0]], d[points[1]], d[points[2]]];
      });

      let dimpoints = dim.top(Infinity);
      const grouparr = dimpoints.map(function (d) {
          return d[points[2]]
        })
        .filter((v, i, a) => a.indexOf(v) === i);
       grouparr.sort();
      let data = [];

      for (groupval of grouparr) {
        data.push({
          x: dimpoints.map(function (d) {
            if (d[points[2]] === groupval) return d[points[0]]
          }),
          y: dimpoints.map(function (d) {
            if (d[points[2]] === groupval) return d[points[1]]
          }),
          name: groupval,
          type: "scatter",
          mode: "markers",
          hovertext: dimpoints.map(function (d) {
            if (d[points[2]] === groupval)
              return `<br>${points[0]}: ${d[points[0]]}<br>${points[1]}: ${d[points[1]]}<br>${points[2]}: ${d[points[2]]} ${hovertext(d,hoverinfo)}`;
          })
        });
      };



      const xmin = Math.floor(
          Math.min.apply(null,dimpoints.map(function (d) {
            return +d[points[0]]
          }))
          
           )

     ;
      
      
      const ymin = Math.floor(
     
          Math.min.apply(null, dimpoints.map(function (d) {
            return +d[points[1]]
          }))
          
          
        )
;
     


      data.push({
        x: dimpoints.map(function (d) {
          return d[points[0]]
        }),
        yaxis: "y2",
        type: "histogram",
        showlegend: false,
        nbinsx: 10,
        xbins: {

          start: xmin
        },

        name: points[0],
        marker: {
          color: "rgba(22,160,133 ,1)",
          line: {
            color: "rgba(0,0,0,1)",
            width: 1
          }
        }

      });

      data.push({
        y: dimpoints.map(function (d) {
          return d[points[1]]
        }),
        xaxis: "x2",
        type: "histogram",
        showlegend: false,
        nbinsy: 10,
        ybins: {

          start: ymin
        },

        name: points[1],
        marker: {
          color: "rgba(22,160,133 ,1)",
          line: {
            color: "rgba(0,0,0,1)",
            width: 1
          }
        }

      });
      data.push({
        yaxis: "y2",
        name: points[1],
        type: "histogram",
   nbinsx: 10,
        xbins: {

          start: xmin
        },
        showlegend: false,
        marker: {
          color: "rgba(44,62,80 ,1)",
          line: {
            color: "rgba(0,0,0,1)",
            width: 1
          }
        }
      });

      data.push({
        xaxis: "x2",
        name: points[0],
        type: "histogram",
  nbinsy: 10,
        ybins: {

          start: ymin
        },

        showlegend: false,
        marker: {
          color: "rgba(44,62,80 ,1)",
          line: {
            color: "rgba(0,0,0,1)",
            width: 1
          }
        }
      });


      let scatterRange = Math.floor(Math.abs.apply(null, [Math.min(
          Math.min.apply(null, dim.top(Infinity).map(function (d) {
            return +d[points[0]]
          })),
          Math.min.apply(null, dim.top(Infinity).map(function (d) {
            return +d[points[1]]
          }))
        ),
        Math.max(
          Math.max.apply(null, dim.top(Infinity).map(function (d) {
            return +d[points[0]]
          })),
          Math.max.apply(null, dim.top(Infinity).map(function (d) {
            return +d[points[1]]
          }))
        )

      ])) + 1;


      let layout = {
        dragmode: "select",
        hovermode: "closest",
        height: "700",
        width: "700",
        xaxis: {
          domain: [0, 0.9],
          /*range: [-scatterRange, scatterRange],*/
          showgrid: false,
          title: {
            text: xtitle
          }
        },
        xaxis2: {
          showgrid: false,
          domain: [0.9, 1],
          tickvals: [],
        },
        yaxis: {
          /*range: [-scatterRange, scatterRange],*/
          showgrid: false,
          domain: [0, 0.9],
          title: {
            text: ytitle
          }
        },
        yaxis2: {
          showgrid: false,
          domain: [0.9, 1],
          tickvals: [],
        },
        barmode: "overlay",
      };

      Plotly.react(div, data, layout, {
        responsive: true
      });

      dim.filterAll();
      dim.dispose();


    };




     function scatterselect(d, div, cf, points) {
       let selected = d.points.map(function (d) {
         return [d.x, d.y, d.data.name];
       });
       let selecteddim = cf.dimension(function (d) {
         return [d[points[0]], d[points[1]], d[points[2]]]
       });
       let selecteddimpoints = selecteddim.top(Infinity);
       const grouparr = selecteddimpoints.map(function (d) {
         return d[points[2]]
       }).filter((v, i, a) => a.indexOf(v) === i);
       selecteddim.filter(function (d) {
         return selected.toString().indexOf(d.toString()) != -1;
       });
       Plotly.restyle(div, {
         'x': [selecteddim.top(Infinity).map(function (d) {
           return d[points[0]]
         })]
       }, [grouparr.length + 2]);
       Plotly.restyle(div, {
         'y': [selecteddim.top(Infinity).map(function (d) {
           return d[points[1]]
         })]
       }, [grouparr.length + 3]);
       onselect(selecteddim, div);
       console.log([selecteddim.top(Infinity), div]);
       selecteddim.filterAll();
       selecteddim.dispose();
     };




    function onfilter(div, dim, points, finddimpoints) {




      const grouparr = &name.dimpoints.map(function (d) {
          return d[points[2]]
        })
        .filter((v, i, a) => a.indexOf(v) === i);

      Plotly.restyle(div, {
        'x': [dim.top(Infinity).map(function (d) {
          return d[points[0]]
        })]
      }, [grouparr.length + 2]);


      Plotly.restyle(div, {
        'y': [dim.top(Infinity).map(function (d) {
          return d[points[1]]
        })]
      }, [grouparr.length + 3]);


      let selectedindices = dim.top(Infinity).map(function (d) {
        if (finddimpoints.indexOf(d) != -1) return finddimpoints.indexOf(d)
      });

      console.log(selectedindices);

      Plotly.restyle(div, {
        'selectedpoints': [selectedindices]
      }, grouparr.map((d) => grouparr.indexOf(d)));




    }



  </script>

;;;;
run;
quit;







  %let nscatter = 1;


%end;


proc stream outfile=plots resetdelim="dosas"; begin



        <div class="row">
          <div class="col-md-12">
            <div class="white-box">
              <h3 class="box-title">&title</h3>
              <div id="&name.scatter"></div>
              <script>
                scatter("&name.scatter", &data.cf, ["&x", "&y", "&color"],[ %quotelst(&hoverinfo.,delim=%str(,)) ],"%varlabel(&data.,&x.)","%varlabel(&data.,&y.)");
                 &name.dimpoints = scatterpoints(&data.cf,  ["&x", "&y", "&color"]);
                document.getElementById("&name.scatter").on("plotly_selected", function (d) {
                  if (d != undefined) {
                    scatterselect(d, "&name.scatter", &data.cf,  ["&x", "&y", "&color"]);
                  } else {
                    scatter("&name.scatter", &data.cf,  ["&x", "&y", "&color"]);
                    resetall();
                  }
                });
              </script>
            </div>
          </div>
        </div>




;;;;
run;
Quit;



proc stream outfile=onselect resetdelim='dosas'; begin


      if (source != "&name.") {
        onfilter("&name.scatter", dim, ["&x", "&y", "&color"], &name.dimpoints);
      };

;;;;
run;
quit;



proc stream outfile=resetall resetdelim='dosas'; begin



      scatter("&name.scatter", &data.cf, ["&x", "&y", "&color"],[%quotelst(&hoverinfo.,delim=%str(,))],"%varlabel(&data.,&x.)","%varlabel(&data.,&y.)");
      &name.dimpoints = scatterpoints(&data.cf, ["&x", "&y", "&color"]);

;;;;
run;
quit;

%mend;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/
libname psug "C:\Users\boddur\OneDrive - Shire PLC\My Projects\PharmaSUG 2019\resources\data\sas from jmp";








data findings;
 set psug.Findings_Shift_Plots;
run;


%init;

%data(findings);
%filters(data=findings,vars=SEX RACE);

%scatter(name=alt,data=findings,x=alt_log2_baseline_uln_,y=alt_log2_trialmean_uln_,color=AGEGR1,hist=y);


%scatter(name=ast,data=findings,x=ast_log2_baseline_uln_,y=ast_log2_trialmean_uln_,color=AGEGR1,hist=y);


%compile(htmlout=C:\Users\boddur\Documents\GitHub\interactive-plots\sas\output\temp.html,
title=Findings temp);




