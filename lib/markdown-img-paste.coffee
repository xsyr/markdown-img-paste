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
        #In case text gets posted into the file Atom should behave nromal
        text = clipboard.readText()
        if(text)
          editor = atom.workspace.getActiveTextEditor()
          editor.insertText(text)
          return
        fileFormat = ""
        if !grammar = cursor.getGrammar() then return
        if cursor.getPath()
            if  cursor.getPath().substr(-3) == '.md' or
                cursor.getPath().substr(-9) == '.markdown' and
                grammar.scopeName != 'source.gfm'
                    fileFormat = "md"
            else if cursor.getPath().substr(-4) == '.rst' and
                grammar.scopeName != 'source.gfm'
                    fileFormat = "rst"
        else
            if grammar.scopeName != 'source.gfm' then return

        if atom.config.get 'markdown-image-paste.only_markdown_and_rst'
            if fileFormat != "md" and
               fileFormat != "rst"
                 return
        else
            #only markdown
            if atom.config.get 'markdown-image-paste.only_markdown'
                if fileFormat != "md" then return
            #only rst
            if atom.config.get 'markdown-image-paste.only_rst'
                if fileFormat != "rst" then return






        img = clipboard.readImage()
        if img.isEmpty() then return

        editor = atom.workspace.getActiveTextEditor()
        words = editor.lineTextForBufferRow(editor.getCursorBufferPosition().row)
        editor.deleteLine()


        #Sets filename based on Name written in the line the cursor was in
        filename = words +  ".png"
        filename = filename.replace(/\s/g, "");

        #Sets up image subfolder
        curDirectory = dirname(cursor.getPath())
        fullname = join(curDirectory, filename)




        mdtext = ""
        mdtext += '![' + words + ']('

        if atom.config.get 'markdown-image-paste.use_subfolder'
          #Finds assets directory path
          subFolderToUse = ""
          subFolderToUse = atom.config.get 'markdown-image-paste.subfolder'
          if subFolderToUse != ""
            assetsDirectory = join(curDirectory, subFolderToUse)

            #Creates directory if necessary
            if !fs.existsSync assetsDirectory
              fs.mkdirSync assetsDirectory


            #Sets full img path
            fullname = join(assetsDirectory, filename)


        mdtext += join(subFolderToUse, filename) + ') '
        mdtext += "\r\n"
        fs.writeFileSync fullname, img.toPng()

        paste_mdtext cursor, mdtext


#辅助函数
delete_file = (file_path) ->
    fs.unlink file_path, (err) ->
        if err
            console.log '未删除本地文件:'+ fullname

paste_mdtext = (cursor, mdtext) ->
    cursor.insertText mdtext
    position = cursor.getCursorBufferPosition()
    position.row = position.row - 1
    position.column = position.column + mdtext.length + 1
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
