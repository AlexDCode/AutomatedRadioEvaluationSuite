# Supporting Functions

## A2dB.m
`File path: src\support\SupportFunctions\A2dB.m`

**DESCRIPTION:**

The function A2dB converts magnitudes (voltage or current) to dB.

```{admonition} Input
:class: note

- A    - Magnitude (voltage or current) in linear scale
```

```{admonition} Output
:class: note

- AdB  - Magnitude in decibels (dB)
```

## dBm2W.m
`File path: src\support\SupportFunctions\dBm2W.m`

**DESCRIPTION:**

The function dBm2mag converts dBm to Watts (W).

```{admonition} Input
:class: note

- PdBm - Power in (dBm)
```

```{admonition} Output
:class: note

- P    -   Power in (W)
```

## extract_docs.m
`File path: src\support\SupportFunctions\extract_docs.m`

**DESCRIPTION:**

EXTRACT_DOCS Extracts help comments from all .m files in a folder. extract_docs('path/to/your/folder', 'path/to/your/outputfile', 'Header String')

## improveAxesAppearance.m
`File path: src\support\SupportFunctions\improveAxesAppearance.m`

**DESCRIPTION:**

This function improves the appearance of axes in MATLAB App Designer, handles plots containing two graphs one on the left y axis and the other on the right y axis, sharing the same x axis. INPUT PARAMETERS axesObj:       Handle to the UIAxes object. varargin:      Optional name-value pairs for 'YYAxis', 'LineWidth'. YYAxis:        Boolean flag, to handle plots with graphs on the left and right y axis, sharing the same x axis. LineThickness: Positive numeric scalar, to handle the thickness.

## loadData.m
`File path: src\support\SupportFunctions\loadData.m`

**DESCRIPTION:**

This function loads data in from a CSV or Excel file containing a single or sweep PA test measurement, or an Antenna test measurement. PARAMETERS RFcomponenet: Either 'PA' or 'Antenna' depending on which type of measurement is being loaded. FileName:     The name of the file that will be loaded into the application. RETURNS combinedData: A struct containing all the data from each column of the loaded file. User can acces specific data by accesing the array's fields.

## saveData.m
`File path: src\support\SupportFunctions\saveData.m`

**DESCRIPTION:**

This function saves data from the application into either a CSV or Excel file. The user passes in the combined test data and combined test variable names, the function saves and organizes the data. PARAMETERS combinedData:  Cell array containing the data for all measurement variables. Example: {testFrequency, testGain, ...} combinedNames: Cell array containing the titles of the measurement variables. Example: {'Frequency Hz', 'Gain dB', ...}

## setupContextMenuFor3DPlot.m
`File path: src\support\SupportFunctions\setupContextMenuFor3DPlot.m`

**DESCRIPTION:**

This function sets up a context menu for the 3D radiation pattern plot created using Antenna Toolbox's internal renderer. INPUT PARAMETERS: app: Application object containing plot handles and export logic. This function: plots

- Creates a right-click context menu on the 3D radiation plot
- Adds export options (PNG, JPG) to the context menu
- Assigns the menu to the axes and all child graphics objects
- Ensures export functionality works even with toolbox-rendered

## waitForInstrument.m
`File path: src\support\SupportFunctions\waitForInstrument.m`

**DESCRIPTION:**

This function waits for an instrument to complete its operation before proceeding. It continuously queries the instrument's operation status and checks if it is ready, or if a specified timeout duration has passed. If the instrument is not ready within the timeout period, the function will exit. INPUT PARAMETERS app:         The application object, which contains settings like the measurement delay value. Instrument:  The instrument object to query for its operation status. OUTPUT PARAMETERS None

## cleanfigure.m
`File path: src\support\SupportFunctions\matlab2tikz\cleanfigure.m`

**DESCRIPTION:**

CLEANFIGURE() removes the unnecessary objects from your MATLAB plot to give you a better experience with matlab2tikz. CLEANFIGURE comes with several options that can be combined at will. CLEANFIGURE('handle',HANDLE,...) explicitly specifies the handle of the figure that is to be stored. (default: gcf) CLEANFIGURE('pruneText',BOOL,...) explicitly specifies whether text should be pruned. (default: true) CLEANFIGURE('targetResolution',PPI,...) CLEANFIGURE('targetResolution',[W,H],...) Reduce the number of data points in line objects by applying unperceivable changes at the target resolution. The target resolution can be specificed as the number of Pixels Per Inch (PPI), e.g. 300, or as the Width and Heigth of the figure in pixels, e.g. [9000, 5400]. Use targetResolution = Inf or 0 to disable line simplification. (default: 600) CLEANFIGURE('scalePrecision',alpha,...) Scale the precision the data is represented with. Setting it to 0 or negative values disable this feature. (default: 1) CLEANFIGURE('normalizeAxis','xyz',...) EXPERIMENTAL: Normalize the data of the dimensions specified by 'normalizeAxis' to the interval [0, 1]. This might have side effects with hgtransform and friends. One can directly pass the axis handle to cleanfigure to ensure that only one axis gets normalized. Usage: Input 'xz' normalizes only x- and zData but not yData (default: '') Example x = -pi:pi/1000:pi; y = tan(sin(x)) - sin(tan(x)); plot(x,y,'--rs'); cleanfigure(); See also: matlab2tikz

## figure2dot.m
`File path: src\support\SupportFunctions\matlab2tikz\figure2dot.m`

**DESCRIPTION:**

FIGURE2DOT    Save figure in Graphviz (.dot) file. FIGURE2DOT(filename) saves the current figure as dot-file. FIGURE2DOT(filename, 'object', HGOBJECT) constructs the graph representation of the specified object (default: gcf) You can visualize the constructed DOT file using: See also: matlab2tikz, cleanfigure, uiinspect, inspect

- [GraphViz](http://www.graphviz.org) on your computer
- [WebGraphViz](http://www.webgraphviz.com) online
- [Gravizo](http://www.gravizo.com) for your markdown files
- and a lot of other software such as OmniGraffle

## m2tInputParser.m
`File path: src\support\SupportFunctions\matlab2tikz\m2tInputParser.m`

**DESCRIPTION:**

MATLAB2TIKZINPUTPARSER   Input parsing for matlab2tikz. This implementation exists because Octave is lacking one.

## m2tcustom.m
`File path: src\support\SupportFunctions\matlab2tikz\m2tcustom.m`

**DESCRIPTION:**

M2TCUSTOM creates user-defined options for matlab2tikz output M2TCUSTOM can be used to create, get and set a properly formatted data structure to customize the conversion of MATLAB figures to TikZ using matlab2tikz. In particular, it allows to: * add blocks of LaTeX/TikZ code around any HG object, * add blocks of comments around any HG object, * add TikZ options to any HG object, * add LaTeX/TikZ code inside some HG objects (e.g. axes), * provide a custom handler to convert a particular HG object. Note that this provides advanced functionality. Only very basic sanity checks are performed such that injudicious use may produce broken TikZ figures! It is HIGHLY recommended that you are comfortable with: * writing pgfplots, TikZ and LaTeX code, * using the Handle Graphics (HG) framework in MATLAB/Octave, and * the inner working of matlab2tikz (for custom handlers) when you use this function. I.e. you should know what you are doing. Usage as a GETTER: value = M2TCUSTOM(handle) retrieves the current custom data structure from the HG object "handle" Usage as a SETTER: M2TCUSTOM(handle, ...) value = M2TCUSTOM(handle, ...) will construct the proper data structure and try to set it to the object |handle| if possible. The arguments (see below) are specified in key-value pairs akin to a normal |struct|, but here we do a few checks and data normalization. If we denote BLOCK to mean either a |char| or a |cellstr|, the following options can be passed. Different entries in a cellstr are assumed separated by a newline. The default values are empty. M2TCUSTOM(handle, 'commentBefore', BLOCK, ...) M2TCUSTOM(handle, 'commentAfter' , BLOCK, ...) to add comments before/after the object. Our code translates newlines and adds the percentage signs for you. M2TCUSTOM(handle, 'codeBefore', BLOCK, ...) M2TCUSTOM(handle, 'codeAfter', BLOCK, ...) M2TCUSTOM(handle, 'codeInsideFirst', BLOCK, ...) M2TCUSTOM(handle, 'codeInsideLast', BLOCK, ...) to add raw LaTeX/TikZ code respectively before, after, as first thing inside or as last thing inside the pgfplots representation of the object. Note that for some HG objects, (e.g. line objects), |codeInsideFirst| and |codeInsideLast| do not make any sense and are hence ignored. M2TCUSTOM(handle, 'extraOptions', OPTIONS, ...) adds extra pgfplots/TikZ options to the end of the option list. Here, OPTIONS is properly formatted TikZ code in M2TCUSTOM(handle, 'customHandler', FUNCTION_HANDLE, ...) allows you to replace the default matlab2tikz handler for this object. This is not for the faint of heart and requires intimate knowledge of the matlab2tikz code base! We expect a function (either as |char| or function handle) that will be called as [m2t, str] = feval(handler, m2t, handle, custom) such that the expected function signature is: function [m2t, str] = handler(m2t, handle, custom) where |m2t| is an undocumented/unstable data structure, |str| is a char containing TikZ code representing the HG object |handle| as generated by your handler, |custom| is a structure as returned by |m2tcustom| from which you only need to handle |extraOptions|, |codeInsideFirst| and |codeInsideLast| when applicable. A particularly useful value for |customHandler| is 'drawNothing', which remove the object from the output. Example: Executing the following MATLAB code fragment: figure; plot(1:10); EOL = sprintf('\n'); m2tCustom(gca, 'codeBefore'      , ['<codeBefore>' EOL]     , ... 'codeAfter'       , ['<codeAfter>'  EOL]     , ... 'commentsBefore'  ,  '<commentsBefore>'      , ... 'commentsAfter'   ,  '<commentsAfter>'       , ... 'codeInsideFirst' , ['<codeInsideFirst>' EOL], ... 'codeInsideLast'  , ['<codeInsideLast>'  EOL], ... 'extraOptions'    ,  '<extraOptions>'); matlab2tikz('test.tikz') Should result in a |test.tikz| file with contents that look somewhat like this: \begin{tikzpicture} <commentsBefore> <codeBefore> \begin{axis}[..., <extraOptions>] <codeInsideFirst> \addplot{...}; <codeInsideLast> \end{axis} <commentsAfter> <codeAfter> \end{tikzpicture} See also: matlab2tikz, setappdata, getappdata

- a |char|    (e.g.  'color=red, line width=1pt'  )
- a |cellstr| (e.g. {'color=red','line width=1pt'})

## matlab2tikz.m
`File path: src\support\SupportFunctions\matlab2tikz\matlab2tikz.m`

**DESCRIPTION:**

MATLAB2TIKZ    Save figure in native LaTeX (TikZ/Pgfplots). MATLAB2TIKZ() saves the current figure as LaTeX file. MATLAB2TIKZ comes with several options that can be combined at will. For example: MATLAB2TIKZ('showInfo', false, 'strict', true, "figure.tex") MATLAB2TIKZ(FILENAME,...) or MATLAB2TIKZ('filename',FILENAME,...) stores the LaTeX code in FILENAME. MATLAB2TIKZ('filehandle',FILEHANDLE,...) stores the LaTeX code in the file referenced by FILEHANDLE. (default: []) MATLAB2TIKZ('figurehandle',FIGUREHANDLE,...) explicitly specifies the handle of the figure that is to be stored. (default: gcf) MATLAB2TIKZ('colormap',DOUBLE,...) explicitly specifies the colormap to be used. (default: current color map) MATLAB2TIKZ('strict',BOOL,...) tells MATLAB2TIKZ to adhere to MATLAB(R) conventions wherever there is room for relaxation. (default: false) MATLAB2TIKZ('strictFontSize',BOOL,...) retains the exact font sizes specified in MATLAB for the TikZ code. This goes against normal LaTeX practice. (default: false) MATLAB2TIKZ('showInfo',BOOL,...) turns informational output on or off. (default: true) MATLAB2TIKZ('showWarnings',BOOL,...) turns warnings on or off. (default: true) MATLAB2TIKZ('imagesAsPng',BOOL,...) stores MATLAB(R) images as (lossless) PNG files. This is more efficient than storing the image color data as TikZ matrix. (default: true) MATLAB2TIKZ('externalData',BOOL,...) stores all data points in external files as tab separated values (TSV files). (default: false) MATLAB2TIKZ('dataPath',CHAR, ...) defines where external data files and/or PNG figures are saved. It can be either an absolute or a relative path with respect to your MATLAB work directory. By default, data files are placed in the same directory as the TikZ output file. To place data files in your MATLAB work directory, you can use '.'. (default: []) MATLAB2TIKZ('relativeDataPath',CHAR, ...) tells MATLAB2TIKZ to use the given path to follow the external data files and PNG files. This is the relative path from your main LaTeX file to the data file directory. By default the same directory is used as the output (default: []) MATLAB2TIKZ('height',CHAR,...) sets the height of the image. This can be any LaTeX-compatible length, e.g., '3in' or '5cm' or '0.5\textwidth'.  If unspecified, MATLAB2TIKZ tries to make a reasonable guess. MATLAB2TIKZ('width',CHAR,...) sets the width of the image. If unspecified, MATLAB2TIKZ tries to make a reasonable guess. MATLAB2TIKZ('noSize',BOOL,...) determines whether 'width', 'height', and 'scale only axis' are specified in the generated TikZ output. For compatibility with the tikzscale package set this to true. (default: false) MATLAB2TIKZ('extraCode',CHAR or CELLCHAR,...) explicitly adds extra code at the beginning of the output file. (default: []) MATLAB2TIKZ('extraCodeAtEnd',CHAR or CELLCHAR,...) explicitly adds extra code at the end of the output file. (default: []) MATLAB2TIKZ('extraAxisOptions',CHAR or CELLCHAR,...) explicitly adds extra options to the Pgfplots axis environment. (default: []) MATLAB2TIKZ('extraColors', {{'name',[R G B]}, ...} , ...) adds user-defined named RGB-color definitions to the TikZ output. R, G and B are expected between 0 and 1. (default: {}) MATLAB2TIKZ('extraTikzpictureOptions',CHAR or CELLCHAR,...) explicitly adds extra options to the tikzpicture environment. (default: []) MATLAB2TIKZ('encoding',CHAR,...) sets the encoding of the output file. MATLAB2TIKZ('floatFormat',CHAR,...) sets the format used for float values. You can use this to decrease the file size. (default: '%.15g') MATLAB2TIKZ('maxChunkLength',INT,...) sets maximum number of data points per \addplot for line plots (default: 4000) MATLAB2TIKZ('parseStrings',BOOL,...) determines whether title, axes labels and the like are parsed into LaTeX by MATLAB2TIKZ's parser. If you want greater flexibility, set this to false and use straight LaTeX for your labels. (default: true) MATLAB2TIKZ('parseStringsAsMath',BOOL,...) determines whether to use TeX's math mode for more characters (e.g. operators and figures). (default: false) MATLAB2TIKZ('showHiddenStrings',BOOL,...) determines whether to show strings whose were deliberately hidden. This is usually unnecessary, but can come in handy for unusual plot types (e.g., polar plots). (default: false) MATLAB2TIKZ('interpretTickLabelsAsTex',BOOL,...) determines whether to interpret tick labels as TeX. MATLAB(R) doesn't allow to do that in R2014a or before. In R2014b and later, please set the "TickLabelInterpreter" property of the relevant axis to get the same effect. (default: false) MATLAB2TIKZ('arrowHeadSize', FLOAT, ...) allows to resize the arrow heads in quiver plots by rescaling the arrow heads by a positive scalar. (default: 10) MATLAB2TIKZ('tikzFileComment',CHAR,...) adds a custom comment to the header of the output file. (default: '') MATLAB2TIKZ('addLabels',BOOL,...) add labels to plots: using Tag property or automatic names (where applicable) which make it possible to refer to them using \ref{...} (e.g., in the caption of a figure). (default: false) MATLAB2TIKZ('standalone',BOOL,...) determines whether to produce a standalone compilable LaTeX file. Setting this to true may be useful for taking a peek at what the figure will look like. (default: false) MATLAB2TIKZ('checkForUpdates',BOOL,...) determines whether to automatically check for updates of matlab2tikz. (default: true (if not using git)) MATLAB2TIKZ('semanticLineWidths',CELLMATRIX,...) allows you to customize the mapping of semantic "line width" values. A valid entry is an Nx2 cell array: The entries you provide are used in addition to the pgf defaults: {'ultra thin', 0.1; 'very thin' , 0.2; 'thin', 0.4; 'semithick', 0.6; 'thick'     , 0.8; 'very thick', 1.2; 'ultra thick', 1.6} or a single "NaN" can be provided to turn off this feature alltogether. If you specify the default names, their mapping will be overwritten. Inside your LaTeX document, you are responsible to make sure these TikZ styles are properly defined. (Default: NaN) Example x = -pi:pi/10:pi; y = tan(sin(x)) - sin(tan(x)); plot(x,y,'--rs'); matlab2tikz('myfile.tex'); See also: cleanfigure

- the first column contains the semantic names,
- the second column contains the corresponding line widths in points.

## formatWhitespace.m
`File path: src\support\SupportFunctions\matlab2tikz\dev\formatWhitespace.m`

**DESCRIPTION:**

FORMATWHITESPACE Formats whitespace and indentation of a document FORMATWHITESPACE(FILENAME) Indents currently active document if FILENAME is empty or not specified. FILENAME must be the name of an open document in the editor. Rules:

- Smart-indent with all function indent option
- Indentation is 4 spaces
- Remove whitespace in empty lines
- Preserve indentantion after line continuations, i.e. ...

## errorUnknownEnvironment.m
`File path: src\support\SupportFunctions\matlab2tikz\private\errorUnknownEnvironment.m`

**DESCRIPTION:**

No documentation provided.

## getEnvironment.m
`File path: src\support\SupportFunctions\matlab2tikz\private\getEnvironment.m`

**DESCRIPTION:**

No documentation provided.

## guitypes.m
`File path: src\support\SupportFunctions\matlab2tikz\private\guitypes.m`

**DESCRIPTION:**

No documentation provided.

## isAxis3D.m
`File path: src\support\SupportFunctions\matlab2tikz\private\isAxis3D.m`

**DESCRIPTION:**

No documentation provided.

## isVersionBelow.m
`File path: src\support\SupportFunctions\matlab2tikz\private\isVersionBelow.m`

**DESCRIPTION:**

No documentation provided.

## m2tUpdater.m
`File path: src\support\SupportFunctions\matlab2tikz\private\m2tUpdater.m`

**DESCRIPTION:**

No documentation provided.

## m2tstrjoin.m
`File path: src\support\SupportFunctions\matlab2tikz\private\m2tstrjoin.m`

**DESCRIPTION:**

No documentation provided.

## versionArray.m
`File path: src\support\SupportFunctions\matlab2tikz\private\versionArray.m`

**DESCRIPTION:**

No documentation provided.

## versionString.m
`File path: src\support\SupportFunctions\matlab2tikz\private\versionString.m`

**DESCRIPTION:**

No documentation provided.

