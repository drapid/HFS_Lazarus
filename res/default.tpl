Welcome! This is the default template for HFS 2.4

Here below you'll find some options affecting the template.
Consider 1 is used for "yes", and 0 is used for "no".

DO NOT EDIT this template just to change options. It's a very bad way to do it, and you'll pay for it!
Correct way: create a new text file 'hfs.diff.tpl' in the same folder of the program.
Add this as first line [+special:strings]
and following all the options you want to change, using the same syntax you see here.
That's all. To know more about diff templates read the documentation.

[+special:strings]
option.newfolder=1
option.move=1
option.comment=1
option.rename=1
COMMENT with the ones above you can disable some features of the template. They apply to all users.

[template id]
def 3.0

[api level]
2

[common-head]
<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="shortcut icon" href="/favicon.ico">
	<link rel="stylesheet" href="/~style.css" type="text/css">
    <script>
	var HFS = {
		user: '{.js encode|%user%.}',
		folder: '{.js encode|%folder%.}',
		sid: '{.cookie|HFS_SID_.}',
		canChangePwd: '{.can change pwd.}',
	}
	</script>
	<script type="text/javascript" src="/~lib.js"></script>

[]
{.$common-head.}
	<title>{.!HFS.} %folder%</title>
	<style class='trash-me'>
	.onlyscript, button[onclick] { display:none; }
	</style>
</head>
<body>
	<div id="wrapper">
	<!--{.comment|--><h1 style='margin-bottom:100em'>WARNING: this template is only to be used with HFS 2.4 (and macros enabled)</h1> <!--.} -->
	{.$menu panel.}
	{.$folder panel.}
	{.$list panel.}
	</div>
</body>
<script>
document.querySelector("main") || music();
</script>
</html>

[list panel]
{.if not| %number% |{:
	<div id='nothing'>{.!{.if|{.length|{.?search.}.}|No results|No files.}.}</div>
:}|{:
	<div id='files' class="hideTs {.for each|z|mkdir|comment|move|rename|delete|{: {.if|{.can {.^z.}.}|can-{.^z.} .}:}.}">
	%list%
	</div>
:}.}
<div id="serverinfo">
	<a href="http://www.rejetto.com/hfs/" title="Build-time: %build-time%"><i class="fa fa-coffee"></i> {.!Uptime.}: %uptime%</a>
</div>


[menu panel]
<script>
$domReady(()=>{
	if ($sel('#menu-panel').style.position.indexOf('sticky') < 0) // sticky is not supported
		setInterval(()=>
			$sel('#wrapper').style.marginTop = $sel('#menu-panel').clientHeight+5, 300); // leave space for the fixed panel
});
</script>

<div id='menu-panel'>
	<div id="title-bar">
		{.$title-bar.}
	</div>
	<div id="menu-bar">
		{.if| {.length|%user%.}
		| <button title="{.!Account panel.}" onclick='showAccount()'><i class='fa fa-user-circle'></i><span>%user%</span></button>
		| <button title="{.!Login.}" onclick='showLogin()'><i class='fa fa-user'></i><span>{.!Login.}</span></button>
		.}
		{.if| {.get|can recur.} |
		<button title="{.!Search.}"
		    onclick="{.if|{.length|{.?search.}.}| location = '.'| $sel(':input', $toggle('search-panel')).focus().}">
			<i class='fa fa-search'></i><span>{.!Search.}</span>
		</button>
		/if.}
		<button id="multiselection" title="{.!Enable multi-selection.}" onclick='toggleSelection()'>
			<i class='fa fa-check'></i>
			<span>{.!Selection.}</span>
		</button>
		{.if|{.can mkdir.}|
			<button title="{.!New folder.}" id='newfolderBtn' onclick='ask(this.innerHTML, "text", name=> ajax("mkdir", { name }))'>
				<i class="fa fa-folder"></i>
				<span>{.!New folder.}</span>
			</button>
		.}
		<button id="toggleTs" title="{.!Display timestamps.}" onclick="toggleTs()">
			<i class='fa fa-clock'></i>
			<span>{.!Toggle timestamp.}</span>
		</button>

		{.if| {.get|can upload.} |{:
			<button id="upload" onclick="upload()" title="{.!Upload.}">
				<i class='fa fa-upload'></i>
				<span>{.!Upload.}</span>
			</button>
		:}.}

		<button id="sort" title="{.!Change list order.}" onclick="changeSort()">
			<i class='fa fa-sort'></i>
			<span>{.!Sort.}</span>
		</button>
	</div>

    <div id="additional-panels">
		{.$search panel.}
		{.$upload panel.}
		<div id="selection-panel" class="additional-panel" style="display:none">
			<label><span id="selected-counter">0</span> {.!selected.}</label>
			<span class="buttons">
				<button id="select-mask"><i class="fa fa-asterisk"></i><span>{.!Mask.}</span></button>
				<button id="select-invert"><i class="fa fa-retweet"></i><span>{.!Invert.}</span></button>
				<button id="delete-selection"><i class="fa fa-trash"></i><span>{.!Delete.}</span></button>
				<button id="move-selection"><i class="fa fa-truck"></i><span>{.!Move.}</span></button>
				{.if|{.get|can archive.}|
				<button id='archive' title="{.!Download selected files as a single archive.}">
					<i class="fa fa-file-archive"></i>
					<span>{.!Archive.}</span>
				</button>
				.}
			</span>
		</div>
    </div>
</div>

[title-bar]
<i class="fa fa-globe"></i> {.!title.}
<i class="fa fa-lightbulb" id="switch-theme"></i>
<script>
var themes = ['light','dark']
var themePostfix = '-theme'
var darkOs = window.matchMedia('(prefers-color-scheme:dark)').matches
var curTheme = localStorage['theme']
if (!themes.includes(curTheme))
	curTheme = themes[+darkOs]
var body = document.body
body.classList.add(curTheme+themePostfix)
$domReady(()=>{

    var titleBar = $sel('#title-bar')
	var h = titleBar.clientHeight
	var k = 'shrink'
    window.onscroll = function(){
        if (window.scrollY > h)
        	titleBar.classList.add(k)
		else if (!window.scrollY)
            titleBar.classList.remove(k)
    }

    $click('#switch-theme', ()=>{
        $xclass(body, curTheme+themePostfix);
		curTheme = themes[themes.indexOf(curTheme) ^1]
        $xclass(body, curTheme+themePostfix);
        localStorage.setItem('theme', curTheme);
    });
});
</script>
<style>
	#title-bar { color:white; height:1.5em; transition:height .2s ease; overflow:hidden; position: relative; top: 0.2em;font-size:120%; }
	#title-bar.shrink { height:0; }
	#foldercomment { clear:left; }
	#switch-theme { color: #aaa; position: absolute; right: .5em; }
</style>

[folder panel]
<div id='folder-path'>
	{.breadcrumbs|{:<button onclick="location.href='%bread-url%' "> {.if|{.length|%bread-name%.}|%bread-name%|<i class='fa fa-home'></i>.}</button>:} .}
</div>
{.if|%number%|
<div id='folder-stats'>
	%number-folders% {.!folders.}, %number-files% {.!files.}, {.add bytes|%total-size%.}
</div>
.}
{.123 if 2| <div id='foldercomment' class="comment"><i class="fa fa-quote-left"></i>|{.commentNL|%folder-item-comment%.}|</div> .}

[upload panel]
<div id="upload-panel" class="additional-panel closeable" style="display:none">
	<div id="upload-counters">
		{.!Uploaded.}: <span id="upload-ok">0</span>
		<span style="display:none"> - {.!Failed.}: <span id="upload-ko">0</span></span>
		- {.!Queued.}: <span id="upload-q">0</span>
	</div>
	<div id="upload-results"></div>
	<div id="upload-progress">
		{.!Uploading....} <span id="progress-text"></span>
		<progress max="1"></progress>
	</div>
	<button onclick="reload()"><i class="fa fa-refresh"></i> {.!Reload page.}</button>
</div>

[search panel]
<div id="search-panel" class="additional-panel closeable" style="{.if not|{.length|{.?search.}.}|display:none.}">
	<form>
		{.!Search.} <input name="search" value="{.escape attr|{.?search.}.}" />
		<br><input type='radio' name='where' value='fromhere' checked='true' />  {.!this folder and sub-folders.}
		<br><input type='radio' name='where' value='here' />  {.!this folder only.}
		<br><input type='radio' name='where' value='anywhere' />  {.!entire server.}
		<button type="submit">{.!Go.}</button>
		<button onclick="return!(location='.')" style="margin-right: 0.3em;">Clear</button>
	</form>
</div>
<style>
	#search-panel [name=search] { margin: 0 0 0.3em 0.1em; }
	#search-panel button { float:right }
</style>
<script>
$on('#search-panel', { submit(ev) {
	var f = $form(ev.target)
	var s = f.search
	if (!s) {
		showError(`{.!Search field is mandatory.}`)
		return false
	}
	var folder = ''
	var ps = []
	switch (f.where) {
		case 'anywhere': folder = '/'
		case 'fromhere':
			ps.push('search='+s)
			break
		case 'here':
			if (s.indexOf('*') < 0)
				s = '*'+s+'*'
			ps.push('files-filter='+s)
			ps.push('folders-filter='+s)
			break
	}
	location = folder+'?'+ps.join('&')
	return false
}})
</script>

[+special:strings]
title=HTTP File Server
max s dl msg=There is a limit on the number of <b>simultaneous</b> downloads on this server.<br>This limit has been reached. Retry later.
retry later=Please, retry later.
item folder=in folder
no files=No files in this folder
no results=No items match your search query
confirm=Are you sure?

[icons.css|public|no log|cache]
@font-face { font-family: 'fontello';
	src: url('data:application/x-font-woff;base64,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') format('woff')
}
.fa { font-family: "fontello"; font-style: normal; font-weight: normal; }
.fa-asterisk:before { content: '\e800'; } /* 'î €' */
.fa-check-circled:before { content: '\e801'; } /* 'î ' */
.fa-user:before { content: '\e802'; } /* 'î ‚' */
.fa-clock:before { content: '\e803'; } /* 'î ƒ' */
.fa-download:before { content: '\e804'; } /* 'î „' */
.fa-upload:before { content: '\e805'; } /* 'î …' */
.fa-ban:before { content: '\e806'; } /* 'î †' */
.fa-edit:before { content: '\e807'; } /* 'î ‡' */
.fa-check:before { content: '\e808'; } /* 'î ˆ' */
.fa-folder:before { content: '\e809'; } /* 'î ‰' */
.fa-globe:before { content: '\e80a'; } /* 'î Š' */
.fa-home:before { content: '\e80b'; } /* 'î ‹' */
.fa-key:before { content: '\e80c'; } /* 'î Œ' */
.fa-lock:before { content: '\e80d'; } /* 'î ' */
.fa-refresh:before { content: '\e80e'; } /* 'î Ž' */
.fa-retweet:before { content: '\e80f'; } /* 'î ' */
.fa-star:before { content: '\e810'; } /* 'î ' */
.fa-cancel-circled:before { content: '\e811'; } /* 'î ‘' */
.fa-truck:before { content: '\e812'; } /* 'î ’' */
.fa-search:before { content: '\e813'; } /* 'î “' */
.fa-logout:before { content: '\e814'; } /* 'î ”' */
.fa-menu:before { content: '\f0c9'; } /* 'ïƒ‰' */
.fa-sort:before { content: '\f0dc'; } /* 'ïƒœ' */
.fa-lightbulb:before { content: '\f0eb'; } /* 'ïƒ«' */
.fa-coffee:before { content: '\f0f4'; } /* 'ïƒ´' */
.fa-quote-left:before { content: '\f10d'; } /* 'ï„' */
.fa-sort-alt-up:before { content: '\f160'; } /* 'ï… ' */
.fa-sort-alt-down:before { content: '\f161'; } /* 'ï…¡' */
.fa-file-archive:before { content: '\f1c6'; } /* 'ï‡†' */
.fa-trash:before { content: '\f1f8'; } /* 'ï‡¸' */
.fa-user-circle:before { content: '\f2bd'; } /* 'ïŠ½' */

[normalize.css|public|no log|cache]
/*! normalize.css v8.0.1 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-webkit-text-size-adjust:100%}body{margin:0}main{display:block}h1{font-size:2em;margin:.67em 0}hr{box-sizing:content-box;height:0;overflow:visible}pre{font-family:monospace,monospace;font-size:1em}a{background-color:transparent}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:bolder}code,kbd,samp{font-family:monospace,monospace;font-size:1em}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}img{border-style:none}button,input,optgroup,select,textarea{font-family:inherit;font-size:100%;line-height:1.15;margin:0}button,input{overflow:visible}button,select{text-transform:none}[type=button],[type=reset],[type=submit],button{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=reset]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=reset]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:1px dotted ButtonText}fieldset{padding:.35em .75em .625em}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}progress{vertical-align:baseline}textarea{overflow:auto}[type=checkbox],[type=radio]{box-sizing:border-box;padding:0}[type=number]::-webkit-inner-spin-button,[type=number]::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}[type=search]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}details{display:block}summary{display:list-item}template{display:none}[hidden]{display:none}

[style.css|public|no log|cache]
{.$normalize.css.}
{.$icons.css.}

button { background-color: #bcd; color: #444; padding: .5em 1em; border: transparent; text-decoration: none; border-radius: .3em; vertical-align: middle; cursor:pointer; }
body { font-family:tahoma, verdana, arial, helvetica, sans; transition:background-color 1s ease; color:#777; }
a { text-decoration:none; color:#357; border:1px solid transparent; padding:0 0.1em; }
#folder-path { float:left; margin-bottom: 0.2em; }
#folder-path button { padding: .4em .6em; border-radius:.7em; }
#folder-path button:first-child { padding: .2em .4em;} #folder-path i.fa { font-size:135% }
button i.fa { font-size:110% }
.item { margin-bottom:.3em; padding:.3em; border-top:1px solid #ddd;  }
.item:hover { background:#f8f8f8; }
.item-props { float:right; font-size:90%; margin-left:12px; margin-top:.2em; }
.item-link { float:left; word-break:break-word; /* fix long names without spaces on mobile */ }
.item img { vertical-align: text-bottom; margin:0 0.2em; }
.item .fa-lock { margin-right: 0.2em; }
.item .clearer { clear:both }
.comment { color:#666; padding:.1em 1.8em .2em; border-radius: 1em; margin-top: 0.1em;
	background-color:rgba(0,0,0,.04); /* dynamically darker, as also hover is darker */  }
.comment>i:first-child { margin-right:0.5em; margin-left:-1.4em; }
.item-size { margin-left:.3em }
.selector { float:left; width: 1.2em; height:1.2em; margin-right: .5em; filter:grayscale(1); }
.item-menu { padding:0.1em 0.3em; border-radius:0.6em; position: relative; top: -0.1em;}
.dialog-content h1 { margin:0; }
.dialog-content .buttons { margin-top:1.5em }
.dialog-content .buttons button { margin:.5em auto; min-width: 9em; display:block; }
.ask .buttons { margin-top:1em }
.ask .buttons button { display:initial; min-width: 6em; }
.dialog-content.error { background: #fcc; }
.dialog-content.error h2 { text-align:center }
.dialog-content.error button { background-color: #f77; color: white; }
#wrapper { max-width:60em; margin:auto; } /* not too wide or it will be harder to follow rows */
#serverinfo { font-size:80%; text-align:center; margin: 1.5em 0 0.5em; }
#selection-panel { text-align:center; }
#selection-panel label { margin-right:0.8em }
#selection-panel button { vertical-align:baseline; }
#selection-panel .buttons { white-space:nowrap }

.item-menu { display:none }
.can-comment .item-menu,
.can-rename .item-menu,
.can-delete .item-menu { display:inline-block; display:initial; }

@keyframes spin { 100% { -webkit-transform: rotate(360deg); transform:rotate(360deg); } }

#folder-stats { font-size:90%; padding:.1em .3em; margin:.5em; float:right; }
#files,#nothing { clear:both }
#nothing { padding:1em }

.dialog-overlay { background:rgba(0,0,0,.75); position:fixed; top:0; left:0; width:100%; height:100%; z-index:100; }
.dialog-content { position: absolute; top: 50%; left: 50%;
	transform: translate(-50%, -50%);
	-webkit-transform: translate(-50%, -50%);
	-moz-transform: translate(-50%, -50%);
	-ms-transform: translate(-50%, -50%);
	-o-transform: translate(-50%, -50%);
	background:#fff; border-radius: 1em; padding: 1em; text-align:center; min-width: 10em;
}
.dialog-content input { border: 1px solid #888; } /* without this the border on chrome83 is not consistent */
.ask input { border:1px solid rgba(0,0,0,0.5); padding: .2em; margin-top:1em; }
.ask textarea { margin:1em 0; width:25em; height:8em; }
.ask .close { float: right; font-size: 1.2em; color: red; position: relative; top: -0.4em; right: -0.3em; }

#additional-panels input { border:0; color: #555; padding: .1em .3em .2em; border-radius: 0.4em; }

.additional-panel { position:relative; max-height: calc(100vh - 5em); text-align:left; margin: 0.5em 1em; padding: 0.5em 1em; border-radius: 1em; background-color:#667; border: 2px solid #aaa; color:#fff; line-height: 1.5em; display:inline-block;  }
.additional-panel .close { position: absolute; right: -0.8em; top: -0.2em; color: #aaa; font-size: 130%; }

body.dark-theme { background:#222; color:#aaa; }
body.dark-theme #menu-panel { background:#345 }
body.dark-theme #title-bar { color:#bbb }
body.dark-theme a { color:#79b }
body.dark-theme .item { border-color:#444; }
body.dark-theme .item:hover { background:#111; }
body.dark-theme button { background:#89a; }
body.dark-theme .item .comment { background-color:#444; color:#888; }
body.dark-theme #foldercomment { background-color:#333; color:#999; }
body.dark-theme .dialog-overlay { background:rgba(100,100,100,.5) }
body.dark-theme .dialog-content { background:#222; color:#888; }
body.dark-theme input,
body.dark-theme textarea,
body.dark-theme select,
body.dark-theme #additional-panels input
{ background: #111; color: #aaa; }

#msgs { display:none; }
#msgs li:first-child { font-weight:bold; }

#menu-panel { position:fixed; top:0; left:0; width: 100%; background:#678; text-align:center;
position: -webkit-sticky; position: -moz-sticky; position: -ms-sticky; position: -o-sticky; position: sticky; margin-bottom:0.3em;
z-index:1; /* without this .item-menu will be over*/ }
#menu-panel button span { margin-left:.8em }
#user-panel button { padding:0.3em 0.6em; font-size:smaller; margin-left:1em; }
#user-panel span { position: relative; top: 0.1em; }
#menu-bar { padding:0.2em 0 }

@media (min-width: 50em) {
#toggleTs { display: none }
}
@media (max-width: 50em) {
#menu-panel button { padding: .4em .6em; }
.additional-panel button span,
#menu-bar button span { display:none } /* icons only */
#menu-bar i { font-size:120%; } /* bigger icons */
#menu-bar button { width: 3em; max-width:10.7vw; padding: .4em 0; }
.hideTs .item-ts { display:none }
}

#upload-panel { font-size: 88%;}
#upload-progress { margin-top:.5em; display:none; }
#upload-progress progress { width:10em; position:relative; top:.1em; }
#progress-text { position: absolute; color: #000; font-size: 80%; margin-left:.5em; z-index:1; }
#upload-results a { color:#b0c2d4; }
#upload-results>* { display:block; word-break: break-all; }
#upload-results>span { margin-left:.15em; } /* better alignment */
#upload-results { max-height: calc(100vh - 11em); overflow: auto;}
#upload-panel>button { margin: auto; display: block; margin-top:.8em;} /* center it*/

[nomacros_style.css|public|no log|cache]
.l{display:inline-block;width:60%}
.t{float:right;color:gray}
#files{width:90%;margin-left:auto;margin-right:auto}
@media (min-width:1280px){#files{width:84%;margin-left:auto;margin-right:auto}}
@media (max-width:800px){#files{width:100%;margin-left:auto;margin-right:auto}.t{float:right;color:#AAA}}
.d{background:transparent;border:none;color:#900;font-size:10pt;cursor:pointer}
.list{float:left;overflow:hidden;background:#fff;border-style:solid;border-width:2px;border-radius:8px;border-color:gray;max-height:90px;width:100%}
.play{padding:0 5px;font-size:7pt;background:#C8F2D0}
.table_title{color:#333;font-style:italic;font-family:serif;text-align:center;font-smoothing:antialiased;font-size:13pt}

button { background-color: #bcd; color: #444; padding: .5em 1em; border: transparent; text-decoration: none; border-radius: .3em; vertical-align: middle; cursor:pointer; }
body { font-family:tahoma, verdana, arial, helvetica, sans; transition:background-color 1s ease; color:#777; }
a { text-decoration:none; color:#357; border:1px solid transparent; padding:0 0.1em; }
#folder-path { float:left; margin-bottom: 0.2em; }
#folder-path button { padding: .4em .6em; border-radius:.7em; }
#folder-path button:first-child { padding: .2em .4em;} #folder-path i.fa { font-size:135% }
button i.fa { font-size:110% }
.item { margin-bottom:.3em; padding:.3em; border-top:1px solid #ddd;  }
.item:hover { background:#f8f8f8; }
.item-props { float:right; font-size:90%; margin-left:12px; margin-top:.2em; }
.item-link { float:left; word-break:break-word; /* fix long names without spaces on mobile */ }
.item img { vertical-align: text-bottom; margin:0 0.2em; }
.item .fa-lock { margin-right: 0.2em; }
.item .clearer { clear:both }
.comment { color:#666; padding:.1em 1.8em .2em; border-radius: 1em; margin-top: 0.1em;
	background-color:rgba(0,0,0,.04); /* dynamically darker, as also hover is darker */  }
.comment>i:first-child { margin-right:0.5em; margin-left:-1.4em; }
.item-size { margin-left:.3em }
.selector { float:left; width: 1.2em; height:1.2em; margin-right: .5em; filter:grayscale(1); }
.item-menu { padding:0.1em 0.3em; border-radius:0.6em; position: relative; top: -0.1em;}
.dialog-content h1 { margin:0; }
.dialog-content .buttons { margin-top:1.5em }
.dialog-content .buttons button { margin:.5em auto; min-width: 9em; display:block; }
.ask .buttons { margin-top:1em }
.ask .buttons button { display:initial; min-width: 6em; }
.dialog-content.error { background: #fcc; }
.dialog-content.error h2 { text-align:center }
.dialog-content.error button { background-color: #f77; color: white; }
#wrapper { max-width:60em; margin:auto; } /* not too wide or it will be harder to follow rows */
#serverinfo { font-size:80%; text-align:center; margin: 1.5em 0 0.5em; }
#selection-panel { text-align:center; }
#selection-panel label { margin-right:0.8em }
#selection-panel button { vertical-align:baseline; }
#selection-panel .buttons { white-space:nowrap }

.item-menu { display:none }
.can-comment .item-menu,
.can-rename .item-menu,
.can-delete .item-menu { display:inline-block; display:initial; }

@keyframes spin { 100% { -webkit-transform: rotate(360deg); transform:rotate(360deg); } }

#folder-stats { font-size:90%; padding:.1em .3em; margin:.5em; float:right; }
#files,#nothing { clear:both }
#nothing { padding:1em }

.dialog-overlay { background:rgba(0,0,0,.75); position:fixed; top:0; left:0; width:100%; height:100%; z-index:100; }
.dialog-content { position: absolute; top: 50%; left: 50%;
	transform: translate(-50%, -50%);
	-webkit-transform: translate(-50%, -50%);
	-moz-transform: translate(-50%, -50%);
	-ms-transform: translate(-50%, -50%);
	-o-transform: translate(-50%, -50%);
	background:#fff; border-radius: 1em; padding: 1em; text-align:center; min-width: 10em;
}
.dialog-content input { border: 1px solid #888; } /* without this the border on chrome83 is not consistent */
.ask input { border:1px solid rgba(0,0,0,0.5); padding: .2em; margin-top:1em; }
.ask textarea { margin:1em 0; width:25em; height:8em; }
.ask .close { float: right; font-size: 1.2em; color: red; position: relative; top: -0.4em; right: -0.3em; }

#additional-panels input { border:0; color: #555; padding: .1em .3em .2em; border-radius: 0.4em; }

.additional-panel { position:relative; max-height: calc(100vh - 5em); text-align:left; margin: 0.5em 1em; padding: 0.5em 1em; border-radius: 1em; background-color:#667; border: 2px solid #aaa; color:#fff; line-height: 1.5em; display:inline-block;  }
.additional-panel .close { position: absolute; right: -0.8em; top: -0.2em; color: #aaa; font-size: 130%; }

body.dark-theme { background:#222; color:#aaa; }
body.dark-theme #menu-panel { background:#345 }
body.dark-theme #title-bar { color:#bbb }
body.dark-theme a { color:#79b }
body.dark-theme .item { border-color:#444; }
body.dark-theme .item:hover { background:#111; }
body.dark-theme button { background:#89a; }
body.dark-theme .item .comment { background-color:#444; color:#888; }
body.dark-theme #foldercomment { background-color:#333; color:#999; }
body.dark-theme .dialog-overlay { background:rgba(100,100,100,.5) }
body.dark-theme .dialog-content { background:#222; color:#888; }
body.dark-theme input,
body.dark-theme textarea,
body.dark-theme select,
body.dark-theme #additional-panels input
{ background: #111; color: #aaa; }
body.dark-theme .list { background:#444; color:#888; }
body.dark-theme .table_title { color:#888; }
#msgs { display:none; }
#msgs li:first-child { font-weight:bold; }

#menu-panel { position:fixed; top:0; left:0; width: 100%; background:#678; text-align:center;
position: -webkit-sticky; position: -moz-sticky; position: -ms-sticky; position: -o-sticky; position: sticky; margin-bottom:0.3em;
z-index:1; /* without this .item-menu will be over*/ }
#menu-panel button span { margin-left:.8em }
#user-panel button { padding:0.3em 0.6em; font-size:smaller; margin-left:1em; }
#user-panel span { position: relative; top: 0.1em; }
#menu-bar { padding:0.2em 0 }

@media (min-width: 50em) {
#toggleTs { display: none }
}
@media (max-width: 50em) {
#menu-panel button { padding: .4em .6em; }
.additional-panel button span,
#menu-bar button span { display:none } /* icons only */
#menu-bar i { font-size:120%; } /* bigger icons */
#menu-bar button { width: 3em; max-width:10.7vw; padding: .4em 0; }
.hideTs .item-ts { display:none }
}

#upload-panel { font-size: 88%;}
#upload-progress { margin-top:.5em; display:none; }
#upload-progress progress { width:10em; position:relative; top:.1em; }
#progress-text { position: absolute; color: #000; font-size: 80%; margin-left:.5em; z-index:1; }
#upload-results a { color:#b0c2d4; }
#upload-results>* { display:block; word-break: break-all; }
#upload-results>span { margin-left:.15em; } /* better alignment */
#upload-results { max-height: calc(100vh - 11em); overflow: auto;}
#upload-panel>button { margin: auto; display: block; margin-top:.8em;} /* center it*/

[file=folder=link|private]
<div class='item item-type-%item-type% {.if|{.get|can access.}||cannot-access.} {.if|{.get|can archive item.}|can-archive.} {.if|{.get|has thumbnail.}|has-thumbnail.}'>
	<div class="item-link">
		<a href="%item-url%">
			<img src="%item-icon%" />
			%item-name%
		</a>
	</div>
	<div class='item-props'>
		<span class="item-ts"><i class='fa fa-clock'></i> {.cut||-3|%item-modified%.}</span>
[+file]
		<span class="item-size"><i class='fa fa-download' title="{.!Download counter:.} %item-dl-count%"></i> %item-size%B</span>
[+file=folder=link]
		{.if|{.get|is new.}|<i class='fa fa-star' title="{.!NEW.}"></i>.}
[+file=folder]
        <button class='item-menu' title="{.!More options.}"><i class="fa fa-menu"></i></button>
[+file=folder=link]
 	</div>
	<div class='clearer'></div>
[+file=folder=link]
    {.if| {.length|{.?search.}.} |{:{.123 if 2|<div class='item-folder'>{.!item folder.} |{.breadcrumbs|{:<a href="%bread-url%">%bread-name%/</a>:}|from={.count substring|/|%folder%.}/breadcrumbs.}|</div>.}:} .}
	{.123 if 2|<div class='comment'><i class="fa fa-quote-left"></i><span class="comment-text">|{.commentNL|%item-comment%.}|</span></div>.}
</div>

[error-page]
{.$common-head.}
  </head>
<body>
%content%
<hr>
<div style="font-family:tahoma, verdana, arial, helvetica, sans; font-size:8pt;">
<a href="http://www.rejetto.com/hfs/">HFS</a> - %timestamp%
</div>
</body>
</html>

[login]
<h1>{.!Login required.}</h1>
<script>showLogin({ closable:false })</script>

[not found]
<h1>{.!Not found.}</h1>
<a href="/">{.!go to root.}</a>

[overload]
<h1>{.!Server Too Busy.}</h1>
{.!The server is too busy to handle your request at this time. Retry later.}

[max contemp downloads]
<h1>{.!Download limit.}</h1>
{.!max s dl msg.}
<br>({.disconnection reason.})

[unauth]
<h1>{.!Unauthorized.}</h1>
{.!Either your user name and password do not match, or you are not permitted to access this resource..}

[deny]
<h1>{.!Forbidden.}</h1>
{.or|%reason%|{.!This resource is not accessible..}.}

[ban]
<h1>{.!You are banned.}</h1>
%reason%

[upload-results]
[{.cut|1|-1|%uploaded-files%.}
]

[upload-success]
{
"url":"%item-url%",
"name":"%item-name%",
"size":"%item-size%",
"speed":"%smart-speed%"
},
{.if| {.length|%user%.} |{:
	{.set item|%folder%%item-name%|comment={.!uploaded by.} %user%.}
:}.}

[upload-failed]
{ "err":"{.!%reason%.}", "name":"%item-name%" },

[progress|no log]
<style>
#progress .fn { font-weight:bold; }
.out_bar { margin-top:0.25em; width:100px; font-size:15px; background:#fff; border:#555 1px solid; margin-right:5px; float:left; }
.in_bar { height:0.5em; background:#47c;  }
</style>
<ul style='padding-left:1.5em;'>
%progress-files%
</ul>

[progress-nofiles]
{.!No file exchange in progress..}

[progress-upload-file]
{.if not|{.{.?only.} = down.}|{:
	<li> {.!Uploading.} %total% @ %speed-kb% KB/s
	<br /><span class='fn'>%filename%</span>
    <br />{.!Time left.} %time-left%"
	<br /><div class='out_bar'><div class='in_bar' style="width:%perc%px"></div></div> %perc%%
:}.}

[progress-download-file]
{.if not|{.{.?only.} = up.}|{:
	<li> {.!Downloading.} %total% @ %speed-kb% KB/s
	<br /><span class='fn'>%filename%</span>
    <br />{.!Time left.} %time-left%"
	<br><div class='out_bar'><div class='in_bar' style="width:%perc%px"></div></div> %perc%%
:}.}

[ajax.mkdir|public|no log]
{.check session.}
{.set|x|{.postvar|name.}.}
{.break|if={.pos|\|var=x.}{.pos|/|var=x.}|result=forbidden.}
{.break|if={.not|{.can mkdir.}.}|result=not authorized.}
{.set|x|%folder%{.^x.}.}
{.break|if={.exists|{.^x.}.}|result=exists.}
{.break|if={.not|{.length|{.mkdir|{.^x.}.}.}.}|result=failed.}
{.add to log|{.!User.} %user% {.!created folder.} "{.^x.}".}
{.pipe|ok.}

[ajax.rename|public|no log]
{.check session.}
{.break|if={.not|{.can rename.}.}|result=forbidden.}
{.break|if={.is file protected|{.postvar|from.}.}|result=forbidden.}
{.break|if={.is file protected|{.postvar|to.}.}|result=forbidden.}
{.set|x|%folder%{.postvar|from.}.}
{.set|yn|{.postvar|to.}.}
{.set|y|%folder%{.^yn.}.}
{.break|if={.not|{.exists|{.^x.}.}.}|result=not found.}
{.break|if={.exists|{.^y.}.}|result=exists.}
{.set|comment| {.get item|{.^x.}|comment.} .}
{.set item|{.^x.}|comment=.}
{.break|if={.not|{.length|{.rename|{.^x.}|{.^yn.}.}.}.}|result=failed.}
{.set item|{.^x.}|resource={.filepath|{.get item|{.^x.}|resource.}.}{.^yn.}.}
{.set item|{.^x.}|name={.^yn.}.}
{.set item|{.^y.}|comment={.^comment.}.}
{.add to log|{.if|%user%|{.!User.} %user%|{.!Anonymous.}.} {.!renamed.} "{.^x.}" {.!to.} "{.^yn.}".}
{.pipe|ok.}

[ajax.move|public|no log]
{.check session.}
{.set|dst|{.postvar|dst.}.}
{.break|if={.not|{.and|{.can move.}|{.get|can upload|path={.^dst.}.}/and.}.} |result=forbidden.}
{.set|log|{.!Moving items to.} {.^dst.}.}
{.for each|fn|{.replace|:|{.no pipe||.}|{.postvar|files.}.}|{:
    {.break|if={.is file protected|var=fn.}|result=forbidden.}
    {.set|x|%folder%{.^fn.}.}
    {.set|y|{.^dst.}/{.^fn.}.}
    {.if not |{.exists|{.^x.}.}|{.^x.}: {.!not found.}|{:
        {.if|{.exists|{.^y.}.}|{.^y.}: {.!already exists.}|{:
            {.set|comment| {.get item|{.^x.}|comment.} .}
            {.set item|{.^x.}|comment=.} {.comment| this must be done before moving, or it will fail.}
            {.if|{.length|{.move|{.^x.}|{.^y.}.}.} |{:
                {.move|{.^x.}.md5|{.^y.}.md5.}
                {.set|log|{.chr|13.}{.^fn.}|mode=append.}
                {.set item|{.^y.}|comment={.^comment.}.}
            :} | {:
                {.set|log|{.chr|13.}{.^fn.} (failed)|mode=append.}
                {.^fn.}: {.!not moved.}
            :}/if.}
        :}/if.}
    :}.}
    ;
:}.}
{.add to log|{.^log.}.}

[ajax.comment|public|no log]
{.check session.}
{.break|if={.not|{.can comment.}.} |result=forbidden.}
{.set|t|{.escape html|{.postvar|text.}.}.}
{.for each|fn|{.replace|:|{.no pipe||.}|{.postvar|files.}.}|{:
     {.break|if={.is file protected|var=fn.}|result=forbidden.}
     {.set item|%folder%{.^fn.}|comment={.^t.}.}
:}.}
{.pipe|ok.}

[ajax.changepwd|public|no log]
{.check session.}
{.break|if={.not|{.can change pwd.}.} |result=forbidden.}
{.if|{.length|{.set account||password={.postvar|new.}.}/length.}|ok|failed.}

[special:alias]
check session=break|if={.{.cookie|HFS_SID_.} != {.postvar|token.}.}|result=bad token
can mkdir=and|{.get|can upload.}|{.!option.newfolder.}
can comment=and|{.get|can upload.}|{.!option.comment.}
can rename=and|{.get|can delete.}|{.!option.rename.}
can delete=get|can delete
can change pwd={.{.member of|can change password.} >.}
can move=and|{.get|can delete.}|{.!option.move.}
escape attr=replace|"|&quot;|$1
escape html=replace|<|&lt;|{.replace|>|&gt;|$1.}
commentNL=if|{.pos|<br|$1.}|$1|{.replace|{.chr|10.}|<br />|$1.}
add bytes=switch|{.cut|-1||$1.}|,|0,1,2,3,4,5,6,7,8,9|$1 {.!Bytes.}|K,M,G,T|$1B

[special:import]
{.new account|can change password|enabled=1|is group=1|notes=accounts members of this group will be allowed to change their password.}

[login.js|public]
function wantArray(x) {
	return Array.isArray(x) ? x : [x]
}

function $create(tag, opts={}){
    let v = tag.split('.')
	tag = v.shift()
    let e = document.createElement(tag)
	if (v.length)
		e.setAttribute('class', v.join(' '))
	if (Array.isArray(opts) || opts instanceof Element)
		opts = { h:opts }
	if (v=opts.s)
	    e.style = v
    if (v=opts.t)
        e.textContent = v
    if (v=opts.h)
		if (typeof v==='string')
			e.innerHTML = v
		else
		    wantArray(v).forEach(x=> e.append(x))
	Object.assign(e, opts.a)
	if (v=opts.on)
		$on(e, v)
	if (v=opts.click)
		$on(e, { click:v })
	if (v=opts.app)
	    $sel(v).append(e)
    return e
}

function $msel(sel, root, opts={}) {
	if (typeof root==='function')
		opts=root, root=0
	if (!root)
		root = document
	sel = sel.replace(/:input\b/g, 'input,textarea,select,button')
	if (opts.single)
	    return root.querySelector(sel)
	let ret = [...root.querySelectorAll(sel)]
	if (typeof opts==='function')
		opts.f = opts
	if (opts.f)
		ret = ret.filter(opts.f)
	return ret
}

function $sel(sel, root){
    if (sel && sel instanceof Element)
        return sel
    return $msel(sel, root, { single:true })
}

function $on(root, evs, sel) {
	if (!root)
		root = document
	if (typeof root==='string')
	    root = $msel(root)
	for (let k in evs)
	    wantArray(root).forEach(r=> r.addEventListener(k, function(ev){
			if (sel && !(ev.delTarget = ev.target.closest(sel)))
				return
			if (false === evs[k].call(this,ev)) {
				ev.stopPropagation()
				ev.preventDefault()
			}
		}))
}

function $click(sel, cb, del) {
    if (typeof sel==='string') {
        let a = sel.split('/')
        if (a.length > 1)
            sel=a[0], del=a[1]
    }
    return $on(sel, { click:cb }, del)
}

function $toggle(id, state) {
	let r = typeof id==='string' ? document.getElementById(id) : id
	if (!r)
		return
	if (state===undefined)
	    state = r.style.display==='none'
	r.style.display = state ? '' : 'none'
	return r
}

function $xclass(el, cls, st) {
    let l = el.classList
    if (st===undefined ? l.contains(cls) : !st)
        return l.remove(cls), false
    l.add(cls)
    return true
}

function $post(url, data, opts) {
    return fetch(url, Object.assign({ method:'POST', cache:'no-cache', body:new URLSearchParams(data) }, opts))
        .then(r=> r.text())
}

function $button(lab, click) {
	let m = lab.split('@@')
	if (m.length > 1)
		lab = '<i class="fa fa-'+m[0]+'"></i> '+m[1]
	return $create('button', { h:lab, click })
}

function $form(form, field) {
    if (typeof form==='string')
        form = $sel(form)
    if (!form.elements)
        form = $sel('form', form)
	if (field)
		return form.elements.namedItem(field).value
	let ret = {}
	for (let e of form.elements)
		if (e.name && (e.type !== 'radio' || e.checked)) {
			let v = e.value
			if (field === false)
				v = v.trim()
			ret[e.name] = v
		}
	return ret
}

function $domReady(cb) {
	document.readyState !== 'loading' ? cb() : document.addEventListener('DOMContentLoaded', cb)
}

// options: cb(function), closable(false)
function dialog(content, options) {
	options = options||{}
	var cb = typeof options==='function' ? options : options.cb
	var active = document.activeElement
    var ret = $create('div.dialog-content', {
		h:content,
		on:{
			click(ev){ ev.stopImmediatePropagation() },
			keydown(ev){ ev.keyCode===27 && close2() }
		}
	})
	ret.close = ()=> {
        ret.closest('.dialog-overlay').remove()
		active.focus()
        cb && cb()
    }
	function close2(){
		if (options.closable !== false)
			ret.close()
	}

	$create('div.dialog-overlay', { h:ret, click:close2, app:'body' })
	setTimeout(()=>
		$sel(':input:not(:disabled)', ret).focus())
    return ret
}//dialog

// options: cb(function), buttons(jq|false)
function showMsg(content, options) {
	options = options||{}
	var cb = typeof options==='function' ? options : options.cb
	var bs = options.buttons
	if (~content.indexOf('<'))
		content = content.replace(/\n/g, '<br>')
    var ret = dialog($create('div', { s:'display:inline-block; text-Align:left' , h:content }), cb)
	//.css('text-align', 'center')
	if (bs!==false)
		$create('div.buttons', {
			app: ret,
			h: bs || $button("{.!Ok.}", ()=> ret.close())
		})
	return ret
}//showMsg

function showError(msg, cb) {
	if (!msg)
		return
	let ret = showMsg("<h2>{.!Error.}</h2>"+msg, cb)
	ret.classList.add('error')
    return ret
}

{.$sha256.js.}

function sha256(s) { return SHA256.hash(s) }

function showLogin(options) {
	if (!HFS.sid) // the session was just deleted
		return location.reload() // but it's necessary for login
	let warning = `<div style='border-bottom:1px solid #888; margin-bottom:1em; padding-bottom:1em;'>
		The current account (${HFS.user}) has no access to this resource.
		<br>Please enter different credentials.
	</div>`
	let d = dialog($create('form', {
		s:'line-height:1.9em',
		// the following works because HFS.user is always a string
		h: (HFS.user && warning)+`
			{.!Username.}
			<br><input name=usr />
			<br>{.!Password.}
			<br><input name=pwd type=password />
			<br><br><button type=submit>{.!Login.}</button>
		`,
		on:{
			submit(){
				var v = $form(d, false)
				var data = {
					user: v.usr,
					passwordSHA256: sha256(sha256(v.pwd)+HFS.sid)  // hash must be lowercase. Double-hashing is causing case sensitiv
				}
				$post("?mode=login", data).then(res=>{
					if (res !== 'ok')
						return showError(res)
					d.close()
					showLoading()
					location.reload()
				}, ajaxError);
				return false
			}
		}
	}), options)
} // showLogin

function showLoading(show){
	if (showLoading.last)
		showLoading.last.close()
	if (show===false)
		return
	let ret = showLoading.last = showMsg('<i class="fa fa-refresh" style="animation:spin 6s linear infinite;position: absolute;top: calc(50% - .5em);left: calc(50% - 0.5em); font-size: 12em; font-size:min(50vw, 50vh); color: #fff;" />',{ buttons:false })
	ret.style.background = 'none'
	return ret
}

[lib.js|public|no log|cache]

{.$login.js.}

function ajax(method, data, cb) {
    if (!data)
        data = {};
    data.token = HFS.sid; // avoid CSRF attacks
    showLoading()
    // calling this section 'under' the current folder will affect permissions commands like {.get|can delete.}
    return $post("?mode=section&id=ajax."+method, data).then(res=>{
        if (cb)
            showLoading(false)
        ;(cb||getStdAjaxCB())(res)
    }, ajaxError);
}//ajax

function changePwd() {
	if (!HFS.canChangePwd)
		return showError("{.!Sorry, you lack permissions for this action.}")
	ask(`{.!Warning: the password will be sent unencrypted to the server. For better security change the password from HFS window..}
		<hr><i class="fa fa-key"></i> {.!Enter new password.}`,
		'password',
		s=>
			s && ajax('changepwd', {'new':s}, getStdAjaxCB(function(){
				showLoading(false)
				showMsg("{.!Password changed.}")
			}))
	)
}//changePwd

function selectionChanged() { $sel('#selected-counter').textContent = getSelectedItems().length }

function getItemName(el) {
    if (!el)
        return false
    var a = el.closest('a') || $sel('.item-link a', el.closest('.item'))
    // take the url, and ignore any #anchor part
    var s = a.href || a.value
    s = s.split('#')[0]
    // remove protocol and hostname
    var i = s.indexOf('://');
    if (i > 0)
        s = s.slice(s.indexOf('/',i+3));
    // current folder is specified. Remove it.
    if (s.indexOf(HFS.folder) == 0)
        s = s.slice(HFS.folder.length);
    // folders have a trailing slash that's not truly part of the name
    if (s.slice(-1) == '/')
        s = s.slice(0,-1);
    // it is encoded
    s = (decodeURIComponent || unescape)(s);
    return s;
} // getItemName

function submit(data, url) {
    var f = $create('form', { app:'body', a:{method:'post', action:url||'' }, s:'display:none' })
    for (var k in data)
		wantArray(data[k]).forEach(v2=>
			$create('input', { app:f, a:{type:'hidden', name:k, value:v2 } }))
    f.submit()
}//submit

RegExp.escape = function(text) {
    if (!arguments.callee.sRE) {
        var specials = '/.*+?|()[]{}\\'.split('');
        arguments.callee.sRE = new RegExp('(\\' + specials.join('|\\') + ')', 'g');
    }
    return text.replace(arguments.callee.sRE, '\\$1');
}//escape


/*  cb: function(value, dialog)
	options: type:string(text,textarea,number), value:any, keypress:function
*/
function ask(msg, options, cb) {
    // 2 parameters means "options" is missing
    if (arguments.length == 2) {
        cb = options;
        options = {};
    }
	if (typeof options==='string')
		options = { type:options }
    msg += '<br />';
    var v = options.type
    var buttons = `<div class=buttons>
		<button>{.!Ok.}</button>
		<button class="cancel">{.!Cancel.}</button>
	</div>`
	if (v == 'textarea')
		msg += '<textarea name="txt">'+options.value+'</textarea>';
	else if (v)
		msg += '<input name="txt" type="'+v+'" value="'+(options.value||'')+'" />';
    msg += buttons
	var ret = dialog( $create('form.ask', { h:msg, on:{
		submit(ev){
		    if (ev.submitter.classList.contains('cancel')
			|| false !== cb(options.type ? $sel(':input', ret).value.trim() : ev.target, ev.target.closest('form'))) {
                ret.close()
                return false
            }
		}
	} }) )

    let i = $sel(':input', ret)
	if (i) {
		i.focus() // autofocus attribute seems to work only first time :(
		if (i.select) i.select() // buttons don't
	}

	return ret
}//ask

// this is a factory for ajax request handlers
function getStdAjaxCB(what2do) {
    return function(res){
        res = res.trim()
        if (res === "ok")
			return (typeof what2do==='function') ? what2do() : location.reload()
		showLoading(false)
		showError(res)
    }
}//getStdAjaxCB

function getSelectedItems() {
    return $msel('#files .selector:checked')
}

function getSelectedItemsName() {
    return getSelectedItems().map(getItemName)
}//getSelectedItemsName

function deleteFiles(files) {
	ask("{.!confirm.}", ()=>{
		submit({ action:'delete', selection:files })
		showLoading()
	})
}//deleteFiles

function moveFiles(files) {
	ask("{.!Enter the destination folder.}", 'text', function(dst) {
		return ajax('move', { dst, files: files.join(':') }, function(res) {
			var a = res.split(';')
			a.pop()
			if (!a.length)
				return showMsg($.trim(res))
			var failed = 0;
			var ok = 0;
			var msg = '';
			a.forEach(s=> {
				s = s.trim()
				if (!s.length) {
					ok++
					return
				}
				failed++;
				msg += s+'\n'
			})
			if (failed)
				msg = "{.!We met the following problems:.}\n"+msg
			msg = (ok ? ok+' {.!files were moved..}\n' : "{.!No file was moved..}\n")+msg
			if (ok)
				showMsg(msg, reload)
			else
				showError(msg)
		})
	})
}//moveFiles

function reload() { location = '.' }

function selectionMask() {
    ask("{.!Please enter the file mask to select.}", {type:'text', value:'*'}, s=>{
        if (!s) return;
        var re = s.match('^/([^/]+)/([a-zA-Z]*)');
        if (re)
            re = new RegExp(re[1], re[2]);
        else {
            var n = s.match(/^(\\*)/)[0].length;
            s = s.substring(n);
            var invert = !!(n % 2); // a leading "\" will invert the logic
            s = RegExp.escape(s).replace(/[?]/g,".");;
            if (s.match(/\\\*/)) {
                s = s.replace(/\\\*/g,".*");
                s = "^ *"+s+" *$"; // in this case var the user decide exactly how it is placed in the string
            }
            re = new RegExp(s, "i");
        }
        $msel( "#files .selector", e=>
			(invert ^ re.test(getItemName(e))) && (e.checked=true))
        selectionChanged()
    });
}//selectionMask

function showAccount() {
	dialog(`<div style="line-height:3em">
			<h1>{.!Account panel.}</h1>
			<span>{.!User.}: ${HFS.user}</span>
			<br><button onclick="changePwd()"><i class="fa fa-key"></i> {.!Change password.}</button>
			<br><button onclick="logout()"><i class="fa fa-logout"></i> {.!Logout.}</button>
        </div>`)
} // showAccount

function logout(){
	showLoading()
	$post('?mode=logout').then(()=> location.reload(), ajaxError);
}

function setCookie(name,value,days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
} // setCookie

function delCookie(name) { setCookie(name,'', -1) }

function getCookie(name) {
	var a = document.cookie.match(new RegExp('(?:^| )' + name + '=([^;]+)'))
	return a && a[1]
} // getCookie

// quando in modalità selezione, viene mostrato una checkbox per ogni item, e viene anche mostrato un pannello per all/none/invert
var multiSelection = false
function toggleSelection() {
    $toggle('selection-panel')
	if (multiSelection = !multiSelection) {
		let base = $create('input.selector', { a:{type:'checkbox'} })
		$msel('.item-selectable .item-link a', e=> // having the checkbox inside the A element will put it on the same line of A even with long A, otherwise A will start on a new line.
			e.append(base.cloneNode()) )
	}
	else
		$msel('#files .selector', x=> x.remove())
}//toggleSelection

function upload(){
	$create('input', {
		a:{ type:'file', name:'file', multiple:true },
		on: { change(ev){
			var files = ev.target.files
			if (!files.length) return
			$toggle('upload-panel')
			uploadQ.add(done=>
				sendFiles(files, done))
		} }
  	}).click()
} //upload

uploadQ = newQ(n=>
    $sel('#upload-q').textContent = Math.max(0, n-1) ) // we don't consider the one we are working

function newQ(onChange){
    var a = []
	var ret = {
		add(job) {
			a.push(job)
			change()
			if (a.length!==1) return
			job(function consume(){
				a.shift() // trash it
				if (a.length)
					a[0](consume) // next
				change()
			})
		}
	}

    function change(){ onChange && onChange(a.length) }

	return ret
}//newQ

function changeSort(){
	let u = urlParams // shortcut
    dialog([
        $create('h3', { t:'{.!Sort by.}' }),
        $create('div.buttons', objToArr(sortOptions, (label,code)=>
            $button( (u.sort===code ? 'sort-alt-'+(u.rev?'down':'up')+'@@' : '')+label, ()=>{
				u.rev = (u.sort===code && !u.rev) ? 1 : undefined
				u.sort = code||undefined
				location.search = encodeURL(urlParams)
			})
		))
	])
}//changeSort

function objToArr(o, cb){
    var ret = []
	for (var k in o) {
	    var v = o[k]
		ret.push(cb(v,k))
	}
	return ret
}

function sendFiles(files, done) {
    var formData = new FormData()
    for (var i = 0; i < files.length; i++)
        formData.append('file', files[i])

	var xhr = new XMLHttpRequest();
	xhr.open('POST', '');
	xhr.send(formData);
	xhr.onload = data=> {
		try {
			data = JSON.parse(data)
			data.forEach(r=> {
				let e = $sel('#upload-'+(r.err ? 'ko' : 'ok'))
				e.textContent = +e.textContent +1
				$toggle(e.parentNode, true) // only for 'ko'
				e = r.err ? $create('span', { a:{title:r.err}, h:'<i class="fa fa-ban"></i> '+ r.name })
					: $create('a', {
						a: { href:r.url, title:"{.!Size.}: '+r.size+'&#013;{.!Speed.}: '+r.speed+'B/s" },
						h: '<i class="fa fa-'+(r.err ? 'ban' : 'check-circled')+'"></i> '+r.name
					})
				$sel('#upload-results').appendChild(e)
			})
		}
		catch(e){
			console.error(e)
			showError('Invalid server reply')
		}
		done()
	}
	xhr.onerror = done

	var e = $sel('#upload-progress')
	var prog = $sel('progress', e)
	prog.value = 0
	$toggle(e)
	var last = 0
	var now = 0
	xhr.onprogress = ev=>
		prog.value = (now = ev.loaded) / ev.total
	var h = setInterval(()=>{
		$sel('#progress-text').textContent = smartSize(now)+'B @ '+smartSize(now-last)+'/s'
		last = now
	},1000)
	xhr.onload = ev=> {
		$toggle(e)
		clearInterval(h)
	}
}//sendFiles

function smartSize(n, options) {
    options = options||{}
	var orders = ['','K','M','G','T','P']
	var order = options.order||1024
	var max = options.maxOrder||orders.length-1
	var i = 0
	while (n >= order && i<max) {
		n /= order
		++i
	}
	if (options.decimals===undefined)
		options.decimals = n<5 ? 1 : 0
	return round(n, options.decimals)
		+orders[i]
}//smartSize

function round(v, digits) {
	return !digits ? Math.round(v) : Math.round(v*Math.pow(10,digits)) / Math.pow(10,digits)
}//round

function log(){
	console.log.apply(console,arguments)
	return arguments[arguments.length-1]
}

function toggleTs(){
    let k = 'hideTs'
    let now = $xclass($sel('#files'), k)
    localStorage.setItem('ts', Number(!now));
}

function decodeURL(urlData) {
	var ret = {}
    for (let x of urlData.split('&')) {
        if (!x) continue
        x = x.split("=").map(decodeURIComponent)
		ret[x[0]] = x.length===1 || x[1]
    }
	return ret
}//decodeURL

function encodeURL(obj) {
    var ret = []
	for (var k in obj) {
	    var v = obj[k]
		if (v===undefined) continue
		k = encodeURIComponent(k)
	    if (v !== true)
	        k += '='+encodeURIComponent(v)
		ret.push(k)
	}
	return ret.join('&')
}//encodeURL

function ajaxError(x){
	showError(x.status || 'communication error')
}

urlParams = decodeURL(location.search.substring(1))
sortOptions = {
	n: "{.!Name.}",
	e: "{.!Extension.}",
	s: "{.!Size.}",
	t: "{.!Timestamp.}",
	d: "{.!Hits.}",
	'': '{.!Default.}'
}

function $icon(name, title, opts) {
    if (typeof opts==='function')
        opts = { click:opts }
	return $create('i.fa.fa-'+name, Object.assign({ title },opts))
}

function mustSelect() {
    return getSelectedItems().length
        || showError(`{.!You need to select some files first.}`)
        && 0
}

$domReady(()=>{
	if (!$sel('#menu-panel')) // this is an error page
		return
    $msel('.trash-me', x=> x.remove()) // this was hiding things for those w/o js capabilities
    if (Number(localStorage['ts']))
        toggleTs()

    $click('/.item-menu', ev=>{
        var it = ev.target.closest('.item')
        var acc = it.matches('.can-access')
        var name = getItemName(ev.target)
        dialog([
            $create('h3', { t:name }),
            $sel('.item-ts', it).cloneNode(true),
            $create('div.buttons', [
                it.closest('.can-delete')
				&& $button('trash@@{.!Delete.}', ()=> deleteFiles([name])),
                it.closest('.can-rename')
				&& $button('edit@@{.!Rename.}', renameItem),
                it.closest('.can-comment')
				&& $button('quote-left@@{.!Comment.}', setComment),
                it.closest('.can-move')
				&& $button('truck@@{.!Move.}', ()=> moveFiles([name]) )
            ])
        ]).classList.add('item-menu-dialog')

        function setComment() {
            let e = $sel('.comment-text',it)
            let value = e && e.textContent || '';
            ask(this.innerHTML, { type: 'textarea', value }, s=>{
                if (s !== value)
                    ajax('comment', { text: s, files: name })
            })
        }//setComment

        function renameItem() {
            ask(this.innerHTML+ ' '+name, { type: 'text', value: name }, to=>
                ajax("rename", { from: name, to }))
        }
    })

	$click('/.selector', ev=>{
		setTimeout(()=>{ // we are keeping the checkbox inside an A tag for layout reasons, and firefox72 is triggering the link when the checkbox is clicked. So we reprogram the behaviour.
			ev.target.checked ^= 1
			selectionChanged()
		})
		return false
	})

	$click('#select-invert', ev=>{
        $msel('#files .selector', x=> x.checked=!x.checked)
        selectionChanged()
    })

    $click('#select-mask', selectionMask)
    $click('#move-selection',()=>
        mustSelect() && moveFiles(getSelectedItemsName()) )
	$toggle('move-selection', $sel('.can-delete'))
    $click('#delete-selection', ()=>
        mustSelect() && deleteFiles(getSelectedItemsName()) )
    $toggle('delete-selection', $sel('.can-delete'))
    $click('#archive', ()=>
        mustSelect() && ask("{.!Downloading many files as archive can be a lengthy operation, and the result is a TAR file. Continue?.}", ()=>
            submit({ selection: getSelectedItemsName() }, "?mode=archive") ))

    $msel('#files .cannot-access .item-link img', x=>
		x.insertAdjacentElement('afterend', $icon('lock', "{.!No access.}") ))
	$msel('#files.can-delete .item:not(.cannot-access), #files .item.can-archive', x=>
		$xclass(x,'item-selectable',1))
    if (! $sel('.item-selectable'))
        $toggle('#multiselection', false)

    $msel('.additional-panel.closeable', x=>
		x.prepend( $icon('times-circle close', 'close', ev=>{
            let e = ev.target.closest('.closeable')
            $toggle(e, false)
            e.dispatchEvent(new CustomEvent('closed'))
        })) )

    $on('#upload-panel', { closed(){
        $sel('#upload-ok').textContent = 0
		$sel('#upload-ko').textContent = 0
        $sel('#upload-results').textContent = ''
    } })

	$sel('#sort span').textContent = sortOptions[urlParams.sort]||'{.!Sort.}'

    selectionChanged()
})//$domReady

function music(){ //C DJ BSD2License
  var e=1,n=new Audio,o=[[]],c=0,r=[];
  document.querySelectorAll("a[href]").forEach(function(t,e){
     var n;[".mp3",".ogg",".m4a",".wma",".aac","flac",".Mp3",".MP3",".OGG",".M4A",".WMA",".AAC","FLAC"].indexOf(t.getAttribute("href").slice(-4))+1&&(o[0].push(t.getAttribute("href")),t.addEventListener("click",function(e){e.preventDefault(),i(t.getAttribute("href"))}),(n=document.querySelector('input[value="'+t.getAttribute("href")+'"]'))&&(n.checked=!0))}),"?shuffle"==location.search&&(e=!e),e&&(o[0]=o[0].sort(function(e,t){return.5-Math.random()}));var t,u=document.querySelector("#actions")||document.querySelector("#menu-bar")||document.querySelector("body"),a=document.createElement("button");function i(e){e.match(/m3u8?$/)?fetch(e).then(function(e){e.text().then(function(e){i(e.match(/^(?!#)(?!\s).*$/gm).map(encodeURI)[0])})}):(n.src=e,n.play(),document.title=decodeURI(e))}a.textContent="\u25BA",a.setAttribute("class","play"),a.onclick=function(){n.paused?(n.src||(n.src=(e?o[0]:t)[0]),n.play()):n.pause()},a.oncontextmenu=function(e){e.preventDefault(),n.onended()},o[0].length&&!document.querySelector("button.play")&&u.appendChild(a),n.onended=function(){var e=n.getAttribute("src");do{e=o[c][o[c].indexOf(e)+1];var t=document.querySelector('input[value="'+e+'"]')}while(t&&!t.checked);e?i(e):c?(c--,n.src=r[c],n.onended()):i(o[0][0])},n.onpause=function(){document.querySelector("button.play").textContent="\u25BA"},n.onplay=function(){document.querySelector("button.play").textContent="\u2759 \u2759"},o[0].length&&(window.onbeforeunload=function(e){localStorage.last=n.getAttribute("src")+"#t="+n.currentTime},t=localStorage.last.split("#t="),n.preload="none",n.src=(e?o[0]:t)[0],(t=1e3*location.search.slice(1))&&setTimeout(function(){document.querySelector("button.play").click()},t)),n.onerror=function(){n.onended()},"mediaSession"in navigator&&navigator.mediaSession.setActionHandler("nexttrack",function(){n.onended()})}


[sha256.js|public]
// from https://github.com/AndersLindman/SHA256
SHA256={K:[1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298],Uint8Array:function(r){return new("undefined"!=typeof Uint8Array?Uint8Array:Array)(r)},Int32Array:function(r){return new("undefined"!=typeof Int32Array?Int32Array:Array)(r)},setArray:function(r,n){if("undefined"!=typeof Uint8Array)r.set(n);else{for(var t=0;t<n.length;t++)r[t]=n[t];for(t=n.length;t<r.length;t++)r[t]=0}},digest:function(r){var n=1779033703,t=3144134277,e=1013904242,a=2773480762,i=1359893119,o=2600822924,A=528734635,f=1541459225,y=SHA256.K;if("string"==typeof r){var v=unescape(encodeURIComponent(r));r=SHA256.Uint8Array(v.length);for(var g=0;g<v.length;g++)r[g]=255&v.charCodeAt(g)}var u=r.length,h=64*Math.floor((u+72)/64),l=h/4,s=8*u,d=SHA256.Uint8Array(h);SHA256.setArray(d,r),d[u]=128,d[h-4]=s>>>24,d[h-3]=s>>>16&255,d[h-2]=s>>>8&255,d[h-1]=255&s;var S=SHA256.Int32Array(l),H=0;for(g=0;g<S.length;g++){var c=d[H]<<24;c|=d[H+1]<<16,c|=d[H+2]<<8,c|=d[H+3],S[g]=c,H+=4}for(var U=SHA256.Int32Array(64),p=0;p<l;p+=16){for(g=0;g<16;g++)U[g]=S[p+g];for(g=16;g<64;g++){var I=U[g-15],w=I>>>7|I<<25;w^=I>>>18|I<<14,w^=I>>>3;var C=(I=U[g-2])>>>17|I<<15;C^=I>>>19|I<<13,C^=I>>>10,U[g]=U[g-16]+w+U[g-7]+C&4294967295}for(var K=n,b=t,m=e,M=a,R=i,j=o,k=A,q=f,g=0;g<64;g++){C=R>>>6|R<<26,C^=R>>>11|R<<21;var x=q+(C^=R>>>25|R<<7)+(R&j^~R&k)+y[g]+U[g]&4294967295,w=K>>>2|K<<30;w^=K>>>13|K<<19;var z=K&b^K&m^b&m,q=k,k=j,j=R,R=M+x&4294967295,M=m,m=b,b=K,K=x+((w^=K>>>22|K<<10)+z&4294967295)&4294967295}n=n+K&4294967295,t=t+b&4294967295,e=e+m&4294967295,a=a+M&4294967295,i=i+R&4294967295,o=o+j&4294967295,A=A+k&4294967295,f=f+q&4294967295}var B=SHA256.Uint8Array(32);for(g=0;g<4;g++)B[g]=n>>>8*(3-g)&255,B[g+4]=t>>>8*(3-g)&255,B[g+8]=e>>>8*(3-g)&255,B[g+12]=a>>>8*(3-g)&255,B[g+16]=i>>>8*(3-g)&255,B[g+20]=o>>>8*(3-g)&255,B[g+24]=A>>>8*(3-g)&255,B[g+28]=f>>>8*(3-g)&255;return B},hash:function(r){var n=SHA256.digest(r),t="";for(i=0;i<n.length;i++){var e="0"+n[i].toString(16);t+=2<e.length?e.substring(1):e}return t}};

[nomacros_lib.js|public|no log|cache]

function wantArray(x) {
	return Array.isArray(x) ? x : [x]
}

function $create(tag, opts={}){
    let v = tag.split('.')
	tag = v.shift()
    let e = document.createElement(tag)
	if (v.length)
		e.setAttribute('class', v.join(' '))
	if (Array.isArray(opts) || opts instanceof Element)
		opts = { h:opts }
	if (v=opts.s)
	    e.style = v
    if (v=opts.t)
        e.textContent = v
    if (v=opts.h)
		if (typeof v==='string')
			e.innerHTML = v
		else
		    wantArray(v).forEach(x=> e.append(x))
	Object.assign(e, opts.a)
	if (v=opts.on)
		$on(e, v)
	if (v=opts.click)
		$on(e, { click:v })
	if (v=opts.app)
	    $sel(v).append(e)
    return e
}

function $msel(sel, root, opts={}) {
	if (typeof root==='function')
		opts=root, root=0
	if (!root)
		root = document
	sel = sel.replace(/:input\b/g, 'input,textarea,select,button')
	if (opts.single)
	    return root.querySelector(sel)
	let ret = [...root.querySelectorAll(sel)]
	if (typeof opts==='function')
		opts.f = opts
	if (opts.f)
		ret = ret.filter(opts.f)
	return ret
}

function $sel(sel, root){
    if (sel && sel instanceof Element)
        return sel
    return $msel(sel, root, { single:true })
}

function $on(root, evs, sel) {
	if (!root)
		root = document
	if (typeof root==='string')
	    root = $msel(root)
	for (let k in evs)
	    wantArray(root).forEach(r=> r.addEventListener(k, function(ev){
			if (sel && !(ev.delTarget = ev.target.closest(sel)))
				return
			if (false === evs[k].call(this,ev)) {
				ev.stopPropagation()
				ev.preventDefault()
			}
		}))
}

function $click(sel, cb, del) {
    if (typeof sel==='string') {
        let a = sel.split('/')
        if (a.length > 1)
            sel=a[0], del=a[1]
    }
    return $on(sel, { click:cb }, del)
}

function $toggle(id, state) {
	let r = typeof id==='string' ? document.getElementById(id) : id
	if (!r)
		return
	if (state===undefined)
	    state = r.style.display==='none'
	r.style.display = state ? '' : 'none'
	return r
}

function $xclass(el, cls, st) {
    let l = el.classList
    if (st===undefined ? l.contains(cls) : !st)
        return l.remove(cls), false
    l.add(cls)
    return true
}

function $post(url, data, opts) {
    return fetch(url, Object.assign({ method:'POST', cache:'no-cache', body:new URLSearchParams(data) }, opts))
        .then(r=> r.text())
}

function $button(lab, click) {
	let m = lab.split('@@')
	if (m.length > 1)
		lab = '<i class="fa fa-'+m[0]+'"></i> '+m[1]
	return $create('button', { h:lab, click })
}

function $form(form, field) {
    if (typeof form==='string')
        form = $sel(form)
    if (!form.elements)
        form = $sel('form', form)
	if (field)
		return form.elements.namedItem(field).value
	let ret = {}
	for (let e of form.elements)
		if (e.name && (e.type !== 'radio' || e.checked)) {
			let v = e.value
			if (field === false)
				v = v.trim()
			ret[e.name] = v
		}
	return ret
}

function $domReady(cb) {
	document.readyState !== 'loading' ? cb() : document.addEventListener('DOMContentLoaded', cb)
}

// options: cb(function), closable(false)
function dialog(content, options) {
	options = options||{}
	var cb = typeof options==='function' ? options : options.cb
	var active = document.activeElement
    var ret = $create('div.dialog-content', {
		h:content,
		on:{
			click(ev){ ev.stopImmediatePropagation() },
			keydown(ev){ ev.keyCode===27 && close2() }
		}
	})
	ret.close = ()=> {
        ret.closest('.dialog-overlay').remove()
		active.focus()
        cb && cb()
    }
	function close2(){
		if (options.closable !== false)
			ret.close()
	}

	$create('div.dialog-overlay', { h:ret, click:close2, app:'body' })
	setTimeout(()=>
		$sel(':input:not(:disabled)', ret).focus())
    return ret
}//dialog

// options: cb(function), buttons(jq|false)
function showMsg(content, options) {
	options = options||{}
	var cb = typeof options==='function' ? options : options.cb
	var bs = options.buttons
	if (~content.indexOf('<'))
		content = content.replace(/\n/g, '<br>')
    var ret = dialog($create('div', { s:'display:inline-block; text-Align:left' , h:content }), cb)
	//.css('text-align', 'center')
	if (bs!==false)
		$create('div.buttons', {
			app: ret,
			h: bs || $button("Ok", ()=> ret.close())
		})
	return ret
}//showMsg

function showError(msg, cb) {
	if (!msg)
		return
	let ret = showMsg("<h2>Error</h2>"+msg, cb)
	ret.classList.add('error')
    return ret
}

// from https://github.com/AndersLindman/SHA256
SHA256={K:[1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298],Uint8Array:function(r){return new("undefined"!=typeof Uint8Array?Uint8Array:Array)(r)},Int32Array:function(r){return new("undefined"!=typeof Int32Array?Int32Array:Array)(r)},setArray:function(r,n){if("undefined"!=typeof Uint8Array)r.set(n);else{for(var t=0;t<n.length;t++)r[t]=n[t];for(t=n.length;t<r.length;t++)r[t]=0}},digest:function(r){var n=1779033703,t=3144134277,e=1013904242,a=2773480762,i=1359893119,o=2600822924,A=528734635,f=1541459225,y=SHA256.K;if("string"==typeof r){var v=unescape(encodeURIComponent(r));r=SHA256.Uint8Array(v.length);for(var g=0;g<v.length;g++)r[g]=255&v.charCodeAt(g)}var u=r.length,h=64*Math.floor((u+72)/64),l=h/4,s=8*u,d=SHA256.Uint8Array(h);SHA256.setArray(d,r),d[u]=128,d[h-4]=s>>>24,d[h-3]=s>>>16&255,d[h-2]=s>>>8&255,d[h-1]=255&s;var S=SHA256.Int32Array(l),H=0;for(g=0;g<S.length;g++){var c=d[H]<<24;c|=d[H+1]<<16,c|=d[H+2]<<8,c|=d[H+3],S[g]=c,H+=4}for(var U=SHA256.Int32Array(64),p=0;p<l;p+=16){for(g=0;g<16;g++)U[g]=S[p+g];for(g=16;g<64;g++){var I=U[g-15],w=I>>>7|I<<25;w^=I>>>18|I<<14,w^=I>>>3;var C=(I=U[g-2])>>>17|I<<15;C^=I>>>19|I<<13,C^=I>>>10,U[g]=U[g-16]+w+U[g-7]+C&4294967295}for(var K=n,b=t,m=e,M=a,R=i,j=o,k=A,q=f,g=0;g<64;g++){C=R>>>6|R<<26,C^=R>>>11|R<<21;var x=q+(C^=R>>>25|R<<7)+(R&j^~R&k)+y[g]+U[g]&4294967295,w=K>>>2|K<<30;w^=K>>>13|K<<19;var z=K&b^K&m^b&m,q=k,k=j,j=R,R=M+x&4294967295,M=m,m=b,b=K,K=x+((w^=K>>>22|K<<10)+z&4294967295)&4294967295}n=n+K&4294967295,t=t+b&4294967295,e=e+m&4294967295,a=a+M&4294967295,i=i+R&4294967295,o=o+j&4294967295,A=A+k&4294967295,f=f+q&4294967295}var B=SHA256.Uint8Array(32);for(g=0;g<4;g++)B[g]=n>>>8*(3-g)&255,B[g+4]=t>>>8*(3-g)&255,B[g+8]=e>>>8*(3-g)&255,B[g+12]=a>>>8*(3-g)&255,B[g+16]=i>>>8*(3-g)&255,B[g+20]=o>>>8*(3-g)&255,B[g+24]=A>>>8*(3-g)&255,B[g+28]=f>>>8*(3-g)&255;return B},hash:function(r){var n=SHA256.digest(r),t="";for(i=0;i<n.length;i++){var e="0"+n[i].toString(16);t+=2<e.length?e.substring(1):e}return t}};


function sha256(s) { return SHA256.hash(s) }

function showLogin(options) {
	if (!HFS.sid) // the session was just deleted
		return location.reload() // but it's necessary for login
	let warning = `<div style='border-bottom:1px solid #888; margin-bottom:1em; padding-bottom:1em;'>
		The current account (${HFS.user}) has no access to this resource.
		<br>Please enter different credentials.
	</div>`
	let d = dialog($create('form', {
		s:'line-height:1.9em',
		// the following works because HFS.user is always a string
		h: (HFS.user && warning)+`
			Username
			<br><input name=usr />
			<br>Password
			<br><input name=pwd type=password />
			<br><br><button type=submit>Login</button>
		`,
		on:{
			submit(){
				var v = $form(d, false)
				var data = {
					user: v.usr,
					passwordSHA256: sha256(sha256(v.pwd)+HFS.sid)  // hash must be lowercase. Double-hashing is causing case sensitiv
				}
				$post("?mode=login", data).then(res=>{
					if (res !== 'ok')
						return showError(res)
					d.close()
					showLoading()
					location.reload()
				}, ajaxError);
				return false
			}
		}
	}), options)
} // showLogin

function showLoading(show){
	if (showLoading.last)
		showLoading.last.close()
	if (show===false)
		return
	let ret = showLoading.last = showMsg('<i class="fa fa-refresh" style="animation:spin 6s linear infinite;position: absolute;top: calc(50% - .5em);left: calc(50% - 0.5em); font-size: 12em; font-size:min(50vw, 50vh); color: #fff;" />',{ buttons:false })
	ret.style.background = 'none'
	return ret
}


function ajax(method, data, cb) {
    if (!data)
        data = {};
    data.token = HFS.sid; // avoid CSRF attacks
    showLoading()
    // calling this section 'under' the current folder will affect permissions commands like 
    return $post("?mode=section&id=ajax."+method, data).then(res=>{
        if (cb)
            showLoading(false)
        ;(cb||getStdAjaxCB())(res)
    }, ajaxError);
}//ajax

function changePwd() {
	if (!HFS.canChangePwd)
		return showError("Sorry, you lack permissions for this action")
	ask(`Warning: the password will be sent unencrypted to the server. For better security change the password from HFS window.
		<hr><i class="fa fa-key"></i> Enter new password`,
		'password',
		s=>
			s && ajax('changepwd', {'new':s}, getStdAjaxCB(function(){
				showLoading(false)
				showMsg("Password changed")
			}))
	)
}//changePwd

function selectionChanged() { $sel('#selected-counter').textContent = getSelectedItems().length }

function getItemName(el) {
    if (!el)
        return false
    var a = el.closest('a') || $sel('.item-link a', el.closest('.item'))
    // take the url, and ignore any #anchor part
    var s = a.href || a.value
    s = s.split('#')[0]
    // remove protocol and hostname
    var i = s.indexOf('://');
    if (i > 0)
        s = s.slice(s.indexOf('/',i+3));
    // current folder is specified. Remove it.
    if (s.indexOf(HFS.folder) == 0)
        s = s.slice(HFS.folder.length);
    // folders have a trailing slash that's not truly part of the name
    if (s.slice(-1) == '/')
        s = s.slice(0,-1);
    // it is encoded
    s = (decodeURIComponent || unescape)(s);
    return s;
} // getItemName

function submit(data, url) {
    var f = $create('form', { app:'body', a:{method:'post', action:url||'' }, s:'display:none' })
    for (var k in data)
		wantArray(data[k]).forEach(v2=>
			$create('input', { app:f, a:{type:'hidden', name:k, value:v2 } }))
    f.submit()
}//submit

RegExp.escape = function(text) {
    if (!arguments.callee.sRE) {
        var specials = '/.*+?|()[]{}\\'.split('');
        arguments.callee.sRE = new RegExp('(\\' + specials.join('|\\') + ')', 'g');
    }
    return text.replace(arguments.callee.sRE, '\\$1');
}//escape


/*  cb: function(value, dialog)
	options: type:string(text,textarea,number), value:any, keypress:function
*/
function ask(msg, options, cb) {
    // 2 parameters means "options" is missing
    if (arguments.length == 2) {
        cb = options;
        options = {};
    }
	if (typeof options==='string')
		options = { type:options }
    msg += '<br />';
    var v = options.type
    var buttons = `<div class=buttons>
		<button>Ok</button>
		<button class="cancel">Cancel</button>
	</div>`
	if (v == 'textarea')
		msg += '<textarea name="txt">'+options.value+'</textarea>';
	else if (v)
		msg += '<input name="txt" type="'+v+'" value="'+(options.value||'')+'" />';
    msg += buttons
	var ret = dialog( $create('form.ask', { h:msg, on:{
		submit(ev){
		    if (ev.submitter.classList.contains('cancel')
			|| false !== cb(options.type ? $sel(':input', ret).value.trim() : ev.target, ev.target.closest('form'))) {
                ret.close()
                return false
            }
		}
	} }) )

    let i = $sel(':input', ret)
	if (i) {
		i.focus() // autofocus attribute seems to work only first time :(
		if (i.select) i.select() // buttons don't
	}

	return ret
}//ask

// this is a factory for ajax request handlers
function getStdAjaxCB(what2do) {
    return function(res){
        res = res.trim()
        if (res === "ok")
			return (typeof what2do==='function') ? what2do() : location.reload()
		showLoading(false)
		showError(res)
    }
}//getStdAjaxCB

function getSelectedItems() {
    return $msel('#files .selector:checked')
}

function getSelectedItemsName() {
    return getSelectedItems().map(getItemName)
}//getSelectedItemsName

function deleteFiles(files) {
	ask("Are you sure?", ()=>{
		submit({ action:'delete', selection:files })
		showLoading()
	})
}//deleteFiles

function moveFiles(files) {
	ask("Enter the destination folder", 'text', function(dst) {
		return ajax('move', { dst, files: files.join(':') }, function(res) {
			var a = res.split(';')
			a.pop()
			if (!a.length)
				return showMsg($.trim(res))
			var failed = 0;
			var ok = 0;
			var msg = '';
			a.forEach(s=> {
				s = s.trim()
				if (!s.length) {
					ok++
					return
				}
				failed++;
				msg += s+'\n'
			})
			if (failed)
				msg = "We met the following problems:\n"+msg
			msg = (ok ? ok+' files were moved.\n' : "No file was moved.\n")+msg
			if (ok)
				showMsg(msg, reload)
			else
				showError(msg)
		})
	})
}//moveFiles

function reload() { location = '.' }

function selectionMask() {
    ask("Please enter the file mask to select", {type:'text', value:'*'}, s=>{
        if (!s) return;
        var re = s.match('^/([^/]+)/([a-zA-Z]*)');
        if (re)
            re = new RegExp(re[1], re[2]);
        else {
            var n = s.match(/^(\\*)/)[0].length;
            s = s.substring(n);
            var invert = !!(n % 2); // a leading "\" will invert the logic
            s = RegExp.escape(s).replace(/[?]/g,".");;
            if (s.match(/\\\*/)) {
                s = s.replace(/\\\*/g,".*");
                s = "^ *"+s+" *$"; // in this case var the user decide exactly how it is placed in the string
            }
            re = new RegExp(s, "i");
        }
        $msel( "#files .selector", e=>
			(invert ^ re.test(getItemName(e))) && (e.checked=true))
        selectionChanged()
    });
}//selectionMask

function showAccount() {
	dialog(`<div style="line-height:3em">
			<h1>Account panel</h1>
			<span>User: ${HFS.user}</span>
			<br><button onclick="changePwd()"><i class="fa fa-key"></i> Change password</button>
			<br><button onclick="logout()"><i class="fa fa-logout"></i> Logout</button>
        </div>`)
} // showAccount

function logout(){
	showLoading()
	$post('?mode=logout').then(()=> location.reload(), ajaxError);
}

function setCookie(name,value,days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
} // setCookie

function delCookie(name) { setCookie(name,'', -1) }

function getCookie(name) {
	var a = document.cookie.match(new RegExp('(?:^| )' + name + '=([^;]+)'))
	return a && a[1]
} // getCookie

// quando in modalità selezione, viene mostrato una checkbox per ogni item, e viene anche mostrato un pannello per all/none/invert
var multiSelection = false
function toggleSelection() {
    $toggle('selection-panel')
	if (multiSelection = !multiSelection) {
		let base = $create('input.selector', { a:{type:'checkbox'} })
		$msel('.item-selectable .item-link a', e=> // having the checkbox inside the A element will put it on the same line of A even with long A, otherwise A will start on a new line.
			e.append(base.cloneNode()) )
	}
	else
		$msel('#files .selector', x=> x.remove())
}//toggleSelection

function upload(){
	$create('input', {
		a:{ type:'file', name:'file', multiple:true },
		on: { change(ev){
			var files = ev.target.files
			if (!files.length) return
			$toggle('upload-panel')
			uploadQ.add(done=>
				sendFiles(files, done))
		} }
  	}).click()
} //upload

uploadQ = newQ(n=>
    $sel('#upload-q').textContent = Math.max(0, n-1) ) // we don't consider the one we are working

function newQ(onChange){
    var a = []
	var ret = {
		add(job) {
			a.push(job)
			change()
			if (a.length!==1) return
			job(function consume(){
				a.shift() // trash it
				if (a.length)
					a[0](consume) // next
				change()
			})
		}
	}

    function change(){ onChange && onChange(a.length) }

	return ret
}//newQ

function changeSort(){
	let u = urlParams // shortcut
    dialog([
        $create('h3', { t:'Sort by' }),
        $create('div.buttons', objToArr(sortOptions, (label,code)=>
            $button( (u.sort===code ? 'sort-alt-'+(u.rev?'down':'up')+'@@' : '')+label, ()=>{
				u.rev = (u.sort===code && !u.rev) ? 1 : undefined
				u.sort = code||undefined
				location.search = encodeURL(urlParams)
			})
		))
	])
}//changeSort

function objToArr(o, cb){
    var ret = []
	for (var k in o) {
	    var v = o[k]
		ret.push(cb(v,k))
	}
	return ret
}

function sendFiles(files, done) {
    var formData = new FormData()
    for (var i = 0; i < files.length; i++)
        formData.append('file', files[i])

	var xhr = new XMLHttpRequest();
	xhr.open('POST', '');
	xhr.send(formData);
	xhr.onload = data=> {
		try {
			data = JSON.parse(data)
			data.forEach(r=> {
				let e = $sel('#upload-'+(r.err ? 'ko' : 'ok'))
				e.textContent = +e.textContent +1
				$toggle(e.parentNode, true) // only for 'ko'
				e = r.err ? $create('span', { a:{title:r.err}, h:'<i class="fa fa-ban"></i> '+ r.name })
					: $create('a', {
						a: { href:r.url, title:"Size: '+r.size+'&#013;Speed: '+r.speed+'B/s" },
						h: '<i class="fa fa-'+(r.err ? 'ban' : 'check-circled')+'"></i> '+r.name
					})
				$sel('#upload-results').appendChild(e)
			})
		}
		catch(e){
			console.error(e)
			showError('Invalid server reply')
		}
		done()
	}
	xhr.onerror = done

	var e = $sel('#upload-progress')
	var prog = $sel('progress', e)
	prog.value = 0
	$toggle(e)
	var last = 0
	var now = 0
	xhr.onprogress = ev=>
		prog.value = (now = ev.loaded) / ev.total
	var h = setInterval(()=>{
		$sel('#progress-text').textContent = smartSize(now)+'B @ '+smartSize(now-last)+'/s'
		last = now
	},1000)
	xhr.onload = ev=> {
		$toggle(e)
		clearInterval(h)
	}
}//sendFiles

function smartSize(n, options) {
    options = options||{}
	var orders = ['','K','M','G','T','P']
	var order = options.order||1024
	var max = options.maxOrder||orders.length-1
	var i = 0
	while (n >= order && i<max) {
		n /= order
		++i
	}
	if (options.decimals===undefined)
		options.decimals = n<5 ? 1 : 0
	return round(n, options.decimals)
		+orders[i]
}//smartSize

function round(v, digits) {
	return !digits ? Math.round(v) : Math.round(v*Math.pow(10,digits)) / Math.pow(10,digits)
}//round

function log(){
	console.log.apply(console,arguments)
	return arguments[arguments.length-1]
}

function toggleTs(){
    let k = 'hideTs'
    let now = $xclass($sel('#files'), k)
    localStorage.setItem('ts', Number(!now));
}

function decodeURL(urlData) {
	var ret = {}
    for (let x of urlData.split('&')) {
        if (!x) continue
        x = x.split("=").map(decodeURIComponent)
		ret[x[0]] = x.length===1 || x[1]
    }
	return ret
}//decodeURL

function encodeURL(obj) {
    var ret = []
	for (var k in obj) {
	    var v = obj[k]
		if (v===undefined) continue
		k = encodeURIComponent(k)
	    if (v !== true)
	        k += '='+encodeURIComponent(v)
		ret.push(k)
	}
	return ret.join('&')
}//encodeURL

function ajaxError(x){
	showError(x.status || 'communication error')
}

urlParams = decodeURL(location.search.substring(1))
sortOptions = {
	n: "Name",
	e: "Extension",
	s: "Size",
	t: "Timestamp",
	d: "Hits",
	'': 'Default'
}

function $icon(name, title, opts) {
    if (typeof opts==='function')
        opts = { click:opts }
	return $create('i.fa.fa-'+name, Object.assign({ title },opts))
}

function mustSelect() {
    return getSelectedItems().length
        || showError(`You need to select some files first`)
        && 0
}

$domReady(()=>{
	if (!$sel('#menu-panel')) // this is an error page
		return
    $msel('.trash-me', x=> x.remove()) // this was hiding things for those w/o js capabilities
    if (Number(localStorage['ts']))
        toggleTs()

    $click('/.item-menu', ev=>{
        var it = ev.target.closest('.item')
        var acc = it.matches('.can-access')
        var name = getItemName(ev.target)
        dialog([
            $create('h3', { t:name }),
            $sel('.item-ts', it).cloneNode(true),
            $create('div.buttons', [
                it.closest('.can-delete')
				&& $button('trash@@Delete', ()=> deleteFiles([name])),
                it.closest('.can-rename')
				&& $button('edit@@Rename', renameItem),
                it.closest('.can-comment')
				&& $button('quote-left@@Comment', setComment),
                it.closest('.can-move')
				&& $button('truck@@Move', ()=> moveFiles([name]) )
            ])
        ]).classList.add('item-menu-dialog')

        function setComment() {
            let e = $sel('.comment-text',it)
            let value = e && e.textContent || '';
            ask(this.innerHTML, { type: 'textarea', value }, s=>{
                if (s !== value)
                    ajax('comment', { text: s, files: name })
            })
        }//setComment

        function renameItem() {
            ask(this.innerHTML+ ' '+name, { type: 'text', value: name }, to=>
                ajax("rename", { from: name, to }))
        }
    })

	$click('/.selector', ev=>{
		setTimeout(()=>{ // we are keeping the checkbox inside an A tag for layout reasons, and firefox72 is triggering the link when the checkbox is clicked. So we reprogram the behaviour.
			ev.target.checked ^= 1
			selectionChanged()
		})
		return false
	})

	$click('#select-invert', ev=>{
        $msel('#files .selector', x=> x.checked=!x.checked)
        selectionChanged()
    })

    $click('#select-mask', selectionMask)
    $click('#move-selection',()=>
        mustSelect() && moveFiles(getSelectedItemsName()) )
	$toggle('move-selection', $sel('.can-delete'))
    $click('#delete-selection', ()=>
        mustSelect() && deleteFiles(getSelectedItemsName()) )
    $toggle('delete-selection', $sel('.can-delete'))
    $click('#archive', ()=>
        mustSelect() && ask("Downloading many files as archive can be a lengthy operation, and the result is a TAR file. Continue?", ()=>
            submit({ selection: getSelectedItemsName() }, "?mode=archive") ))

    $msel('#files .cannot-access .item-link img', x=>
		x.insertAdjacentElement('afterend', $icon('lock', "No access") ))
	$msel('#files.can-delete .item:not(.cannot-access), #files .item.can-archive', x=>
		$xclass(x,'item-selectable',1))
    if (! $sel('.item-selectable'))
        $toggle('#multiselection', false)

    $msel('.additional-panel.closeable', x=>
		x.prepend( $icon('times-circle close', 'close', ev=>{
            let e = ev.target.closest('.closeable')
            $toggle(e, false)
            e.dispatchEvent(new CustomEvent('closed'))
        })) )

    $on('#upload-panel', { closed(){
        $sel('#upload-ok').textContent = 0
		$sel('#upload-ko').textContent = 0
        $sel('#upload-results').textContent = ''
    } })

	$sel('#sort span').textContent = sortOptions[urlParams.sort]||'Sort'

    selectionChanged()
})//$domReady

function music(){ //C DJ BSD2License
  var e=1,n=new Audio,o=[[]],c=0,r=[];
  document.querySelectorAll("a[href]").forEach(function(t,e){
     var n;[".mp3",".ogg",".m4a",".wma",".aac","flac",".Mp3",".MP3",".OGG",".M4A",".WMA",".AAC","FLAC"].indexOf(t.getAttribute("href").slice(-4))+1&&(o[0].push(t.getAttribute("href")),t.addEventListener("click",function(e){e.preventDefault(),i(t.getAttribute("href"))}),(n=document.querySelector('input[value="'+t.getAttribute("href")+'"]'))&&(n.checked=!0))}),"?shuffle"==location.search&&(e=!e),e&&(o[0]=o[0].sort(function(e,t){return.5-Math.random()}));var t,u=document.querySelector("#actions")||document.querySelector("#menu-bar")||document.querySelector("body"),a=document.createElement("button");function i(e){e.match(/m3u8?$/)?fetch(e).then(function(e){e.text().then(function(e){i(e.match(/^(?!#)(?!\s).*$/gm).map(encodeURI)[0])})}):(n.src=e,n.play(),document.title=decodeURI(e))}a.textContent="\u25BA",a.setAttribute("class","play"),a.onclick=function(){n.paused?(n.src||(n.src=(e?o[0]:t)[0]),n.play()):n.pause()},a.oncontextmenu=function(e){e.preventDefault(),n.onended()},o[0].length&&!document.querySelector("button.play")&&u.appendChild(a),n.onended=function(){var e=n.getAttribute("src");do{e=o[c][o[c].indexOf(e)+1];var t=document.querySelector('input[value="'+e+'"]')}while(t&&!t.checked);e?i(e):c?(c--,n.src=r[c],n.onended()):i(o[0][0])},n.onpause=function(){document.querySelector("button.play").textContent="\u25BA"},n.onplay=function(){document.querySelector("button.play").textContent="\u2759 \u2759"},o[0].length&&(window.onbeforeunload=function(e){localStorage.last=n.getAttribute("src")+"#t="+n.currentTime},t=localStorage.last.split("#t="),n.preload="none",n.src=(e?o[0]:t)[0],(t=1e3*location.search.slice(1))&&setTimeout(function(){document.querySelector("button.play").click()},t)),n.onerror=function(){n.onended()},"mediaSession"in navigator&&navigator.mediaSession.setActionHandler("nexttrack",function(){n.onended()})}
