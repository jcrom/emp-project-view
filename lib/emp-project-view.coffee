path = require 'path'
{shell} = require 'electron'
_ = require 'underscore-plus'
{BufferedProcess, CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'
fs = require 'fs-plus'
# TreeViewPath = atom.packages.getActivePackage('tree-view')?.path
AddDialog = null  # Defer requiring until actually needed
MoveDialog = null # Defer requiring until actually needed
CopyDialog = null # Defer requiring until actually needed
Minimatch = null  # Defer requiring until actually needed

{repoForPath, getStyleObject, getFullExtension} = require "./tree-view/helpers"
# console.log TreeViewPath
# Directory = require(path.join(TreeViewPath, 'lib', 'directory'))
Directory = require('./tree-view/directory');
FileView = require('./tree-view/file-view');
DirectoryView = require('./tree-view/directory-view');
RootDragAndDrop = require './tree-view/root-drag-and-drop'
LocalStorage = window.localStorage

module.exports =
class ProjectView extends View
  panel:null

  @content: ->
    @div class: 'proj-view-scroller order--center', outlet: 'emp_scroller', =>
      @ol class: 'proj-view full-menu list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'

  initialize:(@state, @oTreeView, @oEmitterRoute) ->
    @disposables = new CompositeDisposable()
    @roots = []
    @selectedPath = null
    @currentlyOpening = new Map
    @dragEventCounts = new WeakMap
    # @rootDragAndDrop = new RootDragAndDrop(this)

    @oEmitterRoute.doProjNavEmit(@)
    @handleEvents()

    process.nextTick =>
      @onStylesheetsChanged()
      onStylesheetsChanged = _.debounce(@onStylesheetsChanged, 100)
      @disposables.add atom.styles.onDidAddStyleElement(onStylesheetsChanged)
      @disposables.add atom.styles.onDidRemoveStyleElement(onStylesheetsChanged)
      @disposables.add atom.styles.onDidUpdateStyleElement(onStylesheetsChanged)


    @updateRoots(state.directoryExpansionStates)

  serialize:() ->

  deactivate:() ->
    @dispose()

  dispose: () ->
    @panel.destroy()
    @panel = null
    @disposables.dispose()
    # Clean up copy and cut localStorage Variables
    LocalStorage['proj-view:cutPath'] = null
    LocalStorage['proj-view:copyPath'] = null

  do_show:(props) ->
    console.log "do show:", props
    if props.panel is 'project'
      unless @panel
        @panel = @oTreeView.treeView.prepend(@);
      # console.log @list
      @.show()
      @focus()
    else

      @.hide()
      @unfocus()

  focus: ->
    @list.focus()

  unfocus: ->
    atom.workspace.getActivePane().activate()

  hasFocus: ->
    @list.is(':focus') or document.activeElement is @list[0]


  test:() ->
    console.log "do test"

  handleEvents:() ->
    @on 'click', '.entry', (e) =>
      # This prevents accidental collapsing when a .entries element is the event target
      console.log "do check entries"
      return if e.target.classList.contains('entries')
      # console.log "after do check entries-------------"
      @entryClicked(e) unless e.shiftKey or e.metaKey or e.ctrlKey
    @on 'mousedown', '.entry', (e) =>
      console.log "do mousedown"
      @onMouseDown(e)
    atom.commands.add @element,
     'core:move-up': @moveUp.bind(this)
     'core:move-down': @moveDown.bind(this)
     'core:page-up': => @pageUp()
     'core:page-down': => @pageDown()
     'core:move-to-top': => @scrollToTop()
     'core:move-to-bottom': => @scrollToBottom()
     'proj-view:expand-item': => @openSelectedEntry(pending: true, true)
     'proj-view:collapse-directory': => @collapseDirectory()
     "proj-view:remove": => @removeSelectedEntries()
     'proj-view:recursive-expand-directory': => @expandDirectory(true)
     'proj-view:recursive-collapse-directory': => @collapseDirectory(true)
     'proj-view:move': => @moveSelectedEntry()
     'proj-view:copy': => @copySelectedEntries()
     'proj-view:cut': => @cutSelectedEntries()
     'proj-view:paste': => @pasteEntries()
     'proj-view:copy-full-path': => @copySelectedEntryPath(false)
     'proj-view:show-in-file-manager': => @showSelectedEntryInFileManager()
     'proj-view:open-in-new-window': => @openSelectedEntryInNewWindow()
     'proj-view:copy-project-path': => @copySelectedEntryPath(true)
     'proj-view:add-file': => @add(true)
     'proj-view:add-folder': => @add(falsee)
     'proj-view:duplicate': => @copySelectedEntry()

  #
  onStylesheetsChanged: =>
    return unless @isVisible()

    # Force a redraw so the scrollbars are styled correctly based on the theme
    @element.style.display = 'none'
    @element.offsetWidth
    @element.style.display = ''

  onMouseDown: (e) ->
    e.stopPropagation()

    # return early if we're opening a contextual menu (right click) during multi-select mode
    if @multiSelectEnabled() and
       e.currentTarget.classList.contains('selected') and
       # mouse right click or ctrl click as right click on darwin platforms
       (e.button is 2 or e.ctrlKey and process.platform is 'darwin')
      return

    entryToSelect = e.currentTarget

    if e.shiftKey
      @selectContinuousEntries(entryToSelect)
      @showMultiSelectMenu()
    # only allow ctrl click for multi selection on non darwin systems
    else if e.metaKey or (e.ctrlKey and process.platform isnt 'darwin')
      @selectMultipleEntries(entryToSelect)

      # only show the multi select menu if more then one file/directory is selected
      @showMultiSelectMenu() if @selectedPaths().length > 1
    else
      @selectEntry(entryToSelect)
      @showFullMenu()

  # for click
  entryClicked: (e) ->
    entry = e.currentTarget
    isRecursive = e.altKey or false
    @selectEntry(entry)
    if entry instanceof DirectoryView
      # console.log "dp expansion"
      entry.toggleExpansion(isRecursive)
    else if entry instanceof FileView
      @fileViewEntryClicked(e)

    false

  # for file click
  fileViewEntryClicked: (e) ->
    filePath = e.currentTarget.getPath()
    detail = e.originalEvent?.detail ? 1
    alwaysOpenExisting = atom.config.get('tree-view.alwaysOpenExisting')
    if detail is 1
      if atom.config.get('core.allowPendingPaneItems')
        openPromise = atom.workspace.open(filePath, pending: true, activatePane: false, searchAllPanes: alwaysOpenExisting)
        @currentlyOpening.set(filePath, openPromise)
        openPromise.then => @currentlyOpening.delete(filePath)
    else if detail is 2
      @openAfterPromise(filePath, searchAllPanes: alwaysOpenExisting)

  expandDirectory: (isRecursive=false) ->
    selectedEntry = @selectedEntry()
    if isRecursive is false and selectedEntry.isExpanded
      @moveDown() if selectedEntry.directory.getEntries().length > 0
    else
      selectedEntry.expand(isRecursive)

  collapseDirectory: (isRecursive=false) ->
    selectedEntry = @selectedEntry()
    return unless selectedEntry?

    if directory = $(selectedEntry).closest('.expanded.directory')[0]
      directory.collapse(isRecursive)
      @selectEntry(directory)

  openSelectedEntry: (options={}, expandDirectory=false) ->
    selectedEntry = @selectedEntry()
    if selectedEntry instanceof DirectoryView
      if expandDirectory
        @expandDirectory(false)
      else
        selectedEntry.toggleExpansion()
    else if selectedEntry instanceof FileView
      if atom.config.get('tree-view.alwaysOpenExisting')
        options = Object.assign searchAllPanes: true, options
      @openAfterPromise(selectedEntry.getPath(), options)


  openAfterPromise: (uri, options) ->
    if promise = @currentlyOpening.get(uri)
      promise.then -> atom.workspace.open(uri, options)
    else
      atom.workspace.open(uri, options)

  # for select entry
  selectEntry: (entry) ->
    return unless entry?

    @selectedPath = entry.getPath()

    selectedEntries = @getSelectedEntries()
    if selectedEntries.length > 1 or selectedEntries[0] isnt entry
      @deselect(selectedEntries)
      entry.classList.add('selected')
    entry

  # Public: Selects consecutive given entries without clearing previously selected
  #         items. This is cmd+click functionality
  #
  # Returns given entry
  selectMultipleEntries: (entry) ->
    entry?.classList.toggle('selected')
    entry

  # Public: Toggle full-menu class on the main list element to display the full context
  #         menu.
  showFullMenu: ->
    @list[0].classList.remove('multi-select')
    @list[0].classList.add('full-menu')


  # Public: Selects items within a range defined by a currently selected entry and
  #         a new given entry. This is shift+click functionality
  #
  # Returns array of selected elements
  selectContinuousEntries: (entry) ->
    currentSelectedEntry = @selectedEntry()
    parentContainer = $(entry).parent()
    if $.contains(parentContainer[0], currentSelectedEntry)
      entries = parentContainer.find('.entry').toArray()
      entryIndex = entries.indexOf(entry)
      selectedIndex = entries.indexOf(currentSelectedEntry)
      elements = (entries[i] for i in [entryIndex..selectedIndex])

      @deselect()
      element.classList.add('selected') for element in elements

    elements

  # Public: Toggle multi-select class on the main list element to display the the
  #         menu with only items that make sense for multi select functionality
  showMultiSelectMenu: ->
    @list[0].classList.remove('full-menu')
    @list[0].classList.add('multi-select')

  # Public: Check for multi-select class on the main list
  #
  # Returns boolean
  multiSelectEnabled: ->
    @list[0].classList.contains('multi-select')

  # core keybind for move up
  moveUp: (event) ->
    event.stopImmediatePropagation()
    selectedEntry = @selectedEntry()
    if selectedEntry?
      selectedEntry = $(selectedEntry)
      if previousEntry = @selectEntry(selectedEntry.prev('.entry')[0])
        if previousEntry instanceof DirectoryView
          @selectEntry(_.last(previousEntry.entries.children))
      else
        @selectEntry(selectedEntry.parents('.directory').first()?[0])
    else
      @selectEntry(@list.find('.entry').last()?[0])

    @scrollToEntry(@selectedEntry())

  # core keybind for move down
  moveDown: (event) ->
    event?.stopImmediatePropagation()
    selectedEntry = @selectedEntry()
    if selectedEntry?
      if selectedEntry instanceof DirectoryView
        if @selectEntry(selectedEntry.entries.children[0])
          @scrollToEntry(@selectedEntry())
          return

      selectedEntry = $(selectedEntry)
      until @selectEntry(selectedEntry.next('.entry')[0])
        selectedEntry = selectedEntry.parents('.entry:first')
        break unless selectedEntry.length
    else
      @selectEntry(@roots[0])
    @scrollToEntry(@selectedEntry())

  # return the selected entry
  getSelectedEntries: ->
    @list[0].querySelectorAll('.selected')

  selectedEntry: ->
    @list[0].querySelector('.selected')

  selectEntry: (entry) ->
    return unless entry?

    @selectedPath = entry.getPath()
    selectedEntries = @getSelectedEntries()
    if selectedEntries.length > 1 or selectedEntries[0] isnt entry
      @deselect(selectedEntries)
      entry.classList.add('selected')
    entry

  entryForPath: (entryPath) ->
    bestMatchEntry = null
    bestMatchLength = 0

    for entry in @list[0].querySelectorAll('.entry')
      if entry.isPathEqual(entryPath)
        return entry

      entryLength = entry.getPath().length
      if entry.directory?.contains(entryPath) and entryLength > bestMatchLength
        bestMatchEntry = entry
        bestMatchLength = entryLength

    bestMatchEntry

  selectEntryForPath: (entryPath) ->
    @selectEntry(@entryForPath(entryPath))

  # Public: Return an array of paths from all selected items
  #
  # Example: @selectedPaths()
  # => ['selected/path/one', 'selected/path/two', 'selected/path/three']
  # Returns Array of selected item paths
  selectedPaths: ->
    entry.getPath() for entry in @getSelectedEntries()

  # deselect the selected entry
  deselect: (elementsToDeselect=@getSelectedEntries()) ->
    selected.classList.remove('selected') for selected in elementsToDeselect
    undefined

  # scroll to the entry
  scrollToBottom: ->
    if lastEntry = _.last(@list[0].querySelectorAll('.entry'))
      @selectEntry(lastEntry)
      @scrollToEntry(lastEntry)

  scrollToTop: ->
    @selectEntry(@roots[0]) if @roots[0]?
    @scrollTop(0)

  scrollToEntry: (entry) ->
    element = if entry instanceof DirectoryView then entry.header else entry
    element?.scrollIntoViewIfNeeded(true) # true = center
  # some

  getActivePath: -> atom.workspace.getActivePaneItem()?.getPath?()

  #
  copySelectedEntry: ->
    if @hasFocus()
      entry = @selectedEntry()
      return if entry in @roots
      oldPath = entry?.getPath()
    else
      oldPath = @getActivePath()
    return unless oldPath

    CopyDialog ?= require './tree-view/copy-dialog'
    dialog = new CopyDialog(oldPath)
    dialog.attach()

  # delete a entry
  removeSelectedEntries: ->
    if @hasFocus()
      console.log "has focus"
      selectedPaths = @selectedPaths()
    else if activePath = @getActivePath()
      console.log "no focus"
      selectedPaths = [activePath]
    console.log "remove :" ,selectedPaths
    return unless selectedPaths and selectedPaths.length > 0

    for root in @roots
      if root.getPath() in selectedPaths
        atom.confirm
          message: "The root directory '#{root.directory.name}' can't be removed."
          buttons: ['OK']
        return

    atom.confirm
      message: "Are you sure you want to delete the selected #{if selectedPaths.length > 1 then 'items' else 'item'}?"
      detailedMessage: "You are deleting:\n#{selectedPaths.join('\n')}"
      buttons:
        "Move to Trash": ->
          failedDeletions = []
          for selectedPath in selectedPaths
            if not shell.moveItemToTrash(selectedPath)
              failedDeletions.push "#{selectedPath}"
            if repo = repoForPath(selectedPath)
              repo.getPathStatus(selectedPath)
          if failedDeletions.length > 0
            atom.notifications.addError "The following #{if failedDeletions.length > 1 then 'files' else 'file'} couldn't be moved to trash#{if process.platform is 'linux' then " (is `gvfs-trash` installed?)" else ""}",
              detail: "#{failedDeletions.join('\n')}"
              dismissable: true
        "Cancel": null

  # rename a entry
  moveSelectedEntry: ->
    if @hasFocus()
      entry = @selectedEntry()
      return if not entry? or entry in @roots
      oldPath = entry.getPath()
    else
      oldPath = @getActivePath()

    if oldPath
      MoveDialog ?= require './tree-view/move-dialog'
      dialog = new MoveDialog(oldPath)
      dialog.attach()

  # add a new entry
  add: (isCreatingFile) ->
    selectedEntry = @selectedEntry() ? @roots[0]
    selectedPath = selectedEntry?.getPath() ? ''

    AddDialog ?= require './tree-view/add-dialog'
    dialog = new AddDialog(selectedPath, isCreatingFile)
    dialog.on 'directory-created', (event, createdPath) =>
      @entryForPath(createdPath)?.reload()
      @selectEntryForPath(createdPath)
      false
    dialog.on 'file-created', (event, createdPath) ->
      atom.workspace.open(createdPath)
      false
    dialog.attach()

  # Public: Copy the path of the selected entry element.
  #         Save the path in localStorage, so that copying from 2 different
  #         instances of atom works as intended
  #
  #
  # Returns `copyPath`.
  copySelectedEntries: ->
    selectedPaths = @selectedPaths()
    return unless selectedPaths and selectedPaths.length > 0
    # save to localStorage so we can paste across multiple open apps
    LocalStorage.removeItem('proj-view:cutPath')
    LocalStorage['proj-view:copyPath'] = JSON.stringify(selectedPaths)

  copySelectedEntryPath: (relativePath = false) ->
    if pathToCopy = @selectedPath
      pathToCopy = atom.project.relativize(pathToCopy) if relativePath
      atom.clipboard.write(pathToCopy)

  # Public: Copy the path of the selected entry element.
  #         Save the path in localStorage, so that cutting from 2 different
  #         instances of atom works as intended
  #
  #
  # Returns `cutPath`
  cutSelectedEntries: ->
    selectedPaths = @selectedPaths()
    return unless selectedPaths and selectedPaths.length > 0
    # save to localStorage so we can paste across multiple open apps
    LocalStorage.removeItem('proj-view:copyPath')
    LocalStorage['proj-view:cutPath'] = JSON.stringify(selectedPaths)

  # Public: Paste a copied or cut item.
  #         If a file is selected, the file's parent directory is used as the
  #         paste destination.
  #
  #
  # Returns `destination newPath`.
  pasteEntries: ->
    selectedEntry = @selectedEntry()
    cutPaths = if LocalStorage['proj-view:cutPath'] then JSON.parse(LocalStorage['proj-view:cutPath']) else null
    copiedPaths = if LocalStorage['proj-view:copyPath'] then JSON.parse(LocalStorage['proj-view:copyPath']) else null
    initialPaths = copiedPaths or cutPaths

    catchAndShowFileErrors = (operation) ->
      try
        operation()
      catch error
        atom.notifications.addWarning("Unable to paste paths: #{initialPaths}", detail: error.message)

    for initialPath in initialPaths ? []
      initialPathIsDirectory = fs.isDirectorySync(initialPath)
      if selectedEntry and initialPath and fs.existsSync(initialPath)
        basePath = selectedEntry.getPath()
        basePath = path.dirname(basePath) if selectedEntry instanceof FileView
        newPath = path.join(basePath, path.basename(initialPath))

        if copiedPaths
          # append a number to the file if an item with the same name exists
          fileCounter = 0
          originalNewPath = newPath
          while fs.existsSync(newPath)
            if initialPathIsDirectory
              newPath = "#{originalNewPath}#{fileCounter}"
            else
              extension = getFullExtension(originalNewPath)
              filePath = path.join(path.dirname(originalNewPath), path.basename(originalNewPath, extension))
              newPath = "#{filePath}#{fileCounter}#{extension}"
            fileCounter += 1

          if fs.isDirectorySync(initialPath)
            # use fs.copy to copy directories since read/write will fail for directories
            catchAndShowFileErrors -> fs.copySync(initialPath, newPath)
          else
            # read the old file and write a new one at target location
            catchAndShowFileErrors -> fs.writeFileSync(newPath, fs.readFileSync(initialPath))
        else if cutPaths
          # Only move the target if the cut target doesn't exists and if the newPath
          # is not within the initial path
          unless fs.existsSync(newPath) or newPath.startsWith(initialPath)
            catchAndShowFileErrors -> fs.moveSync(initialPath, newPath)

  # get roots
  updateRoots: (expansionStates={}) ->
    oldExpansionStates = {}
    console.log "++++update roots:+++", @roots
    for root in @roots
      oldExpansionStates[root.directory.path] = root.directory.serializeExpansionState()
      root.directory.destroy()
      root.remove()

    @roots = for projectPath in atom.project.getPaths()
      continue unless stats = fs.lstatSyncNoException(projectPath)
      stats = _.pick stats, _.keys(stats)...
      for key in ["atime", "birthtime", "ctime", "mtime"]
        stats[key] = stats[key].getTime()

      directory = new Directory({
        name: path.basename(projectPath)
        fullPath: projectPath
        symlink: false
        isRoot: true
        expansionState: expansionStates[projectPath] ?
                        oldExpansionStates[projectPath] ?
                        {isExpanded: true}
        @ignoredPatterns
        @useSyncFS
        stats
        virDirectory: @getVirtualDirs()
      })
      root = new DirectoryView()
      root.initialize(directory)
      @list[0].appendChild(root)
      root

    if @attachAfterProjectPathSet
      @attach()
      @attachAfterProjectPathSet = false

  getVirtualDirs:() ->
    {
      isVirtual:false,
      directories:{
        "Server":{
          isVirtual:true,
          isExpanded:true,
          isShowRoot:true,
          basedir:"./",
          directories:{
            "config":{

            },
            "drivers":{},
            "include":{},
            "src":{},
            "log":{},
            "ebank.app":{}
          }
        },
        "Frontend":{
          isVirtual:true,
          isExpanded:true,
          isShowRoot:true,
          basedir:"public/www/resource_dev",
          directories:{},
          subdirs:{  # 为二级目录添加虚拟菜单
            "global":{
              isVirtual:true,
              isExpanded:true,

              pathIgnored:["channels"],
              directories:{
              }

            },
            "channels":{
              isVirtual:true,
              isExpanded:true,
              basedir:"channels",
              directories:{
              }
            }
          }
        }
      }
    }
