{WorkspaceView} = require 'atom'
JekyllPreviewView= require '../lib/atom-jekyll'


describe "AtomJekyll", ->
  promise = null
  beforeEach ->
    atom.workspaceView = new JekyllPreviewView()
    atom.workspace = atom.workspaceView.model
    promise = atom.packages.activatePackage('atom-jekyll')
    waitsForPromise ->
      atom.workspace.open()

  it "start_jekyll_preview", ->
    atom.workspaceView.trigger 'atom-jekyll:start_jekyll'
    waitsForPromise ->
      promise
