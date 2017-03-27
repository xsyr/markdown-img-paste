{CompositeDisposable} = require 'atom'
{dirname, join} = require 'path'
clipboard = require 'clipboard'
fs = require 'fs'


module.exports =
    subscriptions : null

    activate : ->
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace',
            'markdown-img-paste:paste' : => @paste()

    deactivate : ->
        @subscriptions.dispose()

    paste : ->
        if !cursor = atom.workspace.getActiveTextEditor() then return
        #only markdown
        if atom.config.get 'markdown-img-paste.only_markdown'
            if !grammar = cursor.getGrammar() then return

            if cursor.getPath()
                if  cursor.getPath().substr(-3) != '.md' and
                    cursor.getPath().substr(-9) != '.markdown' and
                    grammar.scopeName != 'source.gfm'
                        return
            else
                if grammar.scopeName != 'source.gfm' then return



        #In case text gets posted into the file Atom should behave nromal
        text = clipboard.readText()
        if(text)
          editor = atom.workspace.getActiveTextEditor()
          editor.insertText(text)
          return
        img = clipboard.readImage()
        if img.isEmpty() then return

        editor = atom.workspace.getActiveTextEditor()
        words = editor.lineTextForBufferRow(editor.getCursorBufferPosition().row)
        editor.deleteLine()


        #Sets filename based on Name written in the line the cursor was in
        filename = words +  ".png"
        filename = filename.replace(/\s/g, "");

        #Sets up image assets folder
        curDirectory = dirname(cursor.getPath())
        fullname = join(curDirectory, filename)

        #Checks if assets folder is to be used
        if atom.config.get 'markdown-img-paste.use_assets_folder'
          #Finds assets directory path
          assetsDirectory = join(curDirectory, "assets") + "/"

          #Creates directory if necessary
          if !fs.existsSync assetsDirectory
            fs.mkdirSync assetsDirectory


          #Sets full img path
          fullname = join(assetsDirectory, filename)

        fs.writeFileSync fullname, img.toPng()

        mdtext = '![' + words + ']('

        if atom.config.get 'markdown-img-paste.use_assets_folder'
            mdtext += 'assets/'

        mdtext += filename + ')'
        mdtext += "\r\n"

        paste_mdtext cursor, mdtext


#辅助函数
delete_file = (file_path) ->
    fs.unlink file_path, (err) ->
        if err
            console.log '未删除本地文件:'+ fullname

paste_mdtext = (cursor, mdtext) ->
    cursor.insertText mdtext
    position = cursor.getCursorBufferPosition()
    position.column = position.column - mdtext.length + 2
    cursor.setCursorBufferPosition position



Date.prototype.format = ->

    shift2digits = (val) ->
        if val < 10
            return "0#{val}"
        return val

    year = @getFullYear()
    month = shift2digits @getMonth()+1
    day = shift2digits @getDate()
    hour = shift2digits @getHours()
    minute = shift2digits @getMinutes()
    second = shift2digits @getSeconds()
    ms = shift2digits @getMilliseconds()

    return "#{year}#{month}#{day}#{hour}#{minute}#{second}#{ms}"
