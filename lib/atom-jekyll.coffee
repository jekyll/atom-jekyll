http = require 'http'
url = require 'url'
path= require 'path'
fs = require 'fs'
{$, $$$, ScrollView} = require 'atom'
get_url_for = (uri)->
  file_name = path.basename uri
  groups=/([0-9]+)[-]([0-9]+)[-]([0-9]+)[-](.*)/.exec(file_name.replace(".markdown", ".html"))
  url = "http://localhost:4000/jekyll/update/" + groups.splice(1,groups.length).join("/")
  return url

class JekyllPreviewView extends ScrollView
  constructor: (id, url)->
   console.log "Construct Jekyll Preview View. #{JSON.stringify arguments}"
   this["url"]=url
   super
  destroy: ->
    console.log "Destroy called"
    if (this['jekyll-process'] != undefined)
        this['jekyll-process'].kill('SIGHUP');


  @content: ->
    @iframe
      class: 'preview native-key-bindings'
      tabindex: -1
      style: 'background:white; width:100%; height:100%'
      src: arguments[1] || 'http://localhost:4000/'


  getTitle: ->
    "Jekyll Preview"



module.exports =
  JekyllPreviewView:JekyllPreviewView
  activate: ->
    console.log('loading jekyll-preview')
    atom.workspaceView.command "atom-jekyll:start_jekyll", => @start_jekyll()
    atom.workspace.registerOpener (uriToOpen) ->
      console.log('open' + uriToOpen)
      # if not uriToOpen.startsWith("jekyll-preview:")
      #   return
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        console.log error
        return
      console.log('uri:' + protocol)
      return unless protocol is 'jekyll-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      #if host is 'editor'
      console.log('Creating Jekyll view.' + JekyllPreviewView)
      try
        view = new JekyllPreviewView(editorId="jekyll-preview", url=get_url_for(pathname))
      catch err
        console.log err

      view.on 'pane:close', ->
        console.log 'close event ---------------';
      return view


  jekyll_ws: (uri)->
    console.log uri

    if uri == path.dirname(uri)
      return false
    if uri.length <= 1
      return false

    if fs.existsSync(path.join(path.dirname(uri), '_config.yml'))
      return path.dirname(uri)
    else
      return @jekyll_ws(path.dirname(uri))


  start_jekyll: ->
    active_uri = atom.workspace.activePaneItem.getUri()
    workspace_home = @jekyll_ws(active_uri)
    if workspace_home
      spawn = require('child_process').spawn
      proc  = spawn('jekyll', ['serve', '--watch'], {'cwd':workspace_home});

      proc.stdout.on('data', (data) ->
         console.log('' + data);
         if /[.][.][.]done[.]/.test data
           console.log('reloading')
           proc["view"][0].contentWindow.location.reload();
         if /Server running/.test data
            atom.workspace.open("jekyll-preview://local/" + path.basename(active_uri) , {"split":"right"}).done (view) ->
              console.log 'adding panel'
              view['jekyll-process']=proc;
              proc["view"] = view
              window.view = view;
              try
                url = get_url_for(active_uri);
                view["url"]=url
              catch error
               console.log "Unable to get url for #{active_uri} : #{error}"
              atom.workspaceView.on 'pane:removed', ->
                console.log 'destroyed' + arguments

      );
      proc.on('close', (code, signal) ->
       console.log('child process terminated due to receipt of signal '+signal)
      );
    else
      alert('Could not find jekyll workspace\n Not found config "_config.yml" for the file \n ' + active_uri)
