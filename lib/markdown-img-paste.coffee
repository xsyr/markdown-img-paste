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
        try
          # In case we are not in an active Texteditor window it makes no sense to add markdown or rst images
          if !cursor = atom.workspace.getActiveTextEditor() then return
          #In case text gets posted into the file Atom should behave normal
          text = clipboard.readText()
          # if the user copied text we don't care about different formats.
          # just let him do it
          editor = atom.workspace.getActiveTextEditor()
          if(text)
            editor.insertText(text)
            return

          fileFormat = ""
          if !grammar = cursor.getGrammar() then return
          if cursor.getPath()
              # We are in a markdown file
              if  cursor.getPath().substr(-3) == '.md' or
                  cursor.getPath().substr(-9) == '.markdown' and
                  grammar.scopeName != 'source.gfm'
                      fileFormat = "md"
              # We are in a RST file
              else if cursor.getPath().substr(-4) == '.rst' and
                  grammar.scopeName != 'source.gfm'
                      fileFormat = "rst"
          else
              if grammar.scopeName != 'source.gfm' then return



          img = clipboard.readImage()
          # If the image is empty there is obviously nothing we could add anyways
          if img.isEmpty() then return

          # Words equals the text in the current line of the cursor
          words = editor.lineTextForBufferRow(editor.getCursorBufferPosition().row)
          # We delete anything in the current line
          editor.deleteLine()

          singleWords = words.split(" ")
          filename = ""
          underlines = false
          allLower = false
          if atom.config.get 'markdown-image-paste.spacesToUnderlines'
            underlines = true

          if atom.config.get 'markdown-image-paste.allLettersLowerCase'
            allLower = true

          for word in singleWords
            if(allLower)
              filename +=  word.toLowerCase();
            else
              filename += word;
            if(underlines)
              filename +=  "_"

          #Delete the last `_`
          if(underlines)
            if(filename.endsWith("_"))
              filename = filename.substring(0, filename.lastIndexOf("_"))


          #Sets filename based on text written in the line the cursor was in
          filename += ".png"
          #We dont want spaces in our filename. Special charackters are not considered yet
          filename = filename.replace(/\s/g, "");

          #Sets up image subfolder
          curDirectory = dirname(cursor.getPath())
          # Join adds a platform independent directory separator
          fullname = join(curDirectory, filename)

          subFolderToUse = ""

          jekyllRootDir = ""
          if atom.config.get 'markdown-image-paste.enableJekyllSupport'
             jekyllImageDir = atom.config.get 'markdown-image-paste.jekyllImageDir'
             if jekyllImageDir == ""
               paste_text "jekyllImageDir must be configured.\n"
               return

            configDir = curDirectory
            while true
              if fs.existsSync join(configDir, "_config.yml")
                jekyllRootDir = configDir
                break
              configDir = join(configDir, "..")
              if configDir == "/"
                break

            fullname = join(jekyllRootDir, jekyllImageDir, filename)
            subFolderToUse = jekyllImageDir

          if jekyllRootDir == "" and atom.config.get 'markdown-image-paste.use_subfolder'
            #Finds  directory path

            subFolderToUse = atom.config.get 'markdown-image-paste.subfolder'
            if subFolderToUse != ""
              assetsDirectory = join(curDirectory, subFolderToUse)

              #Creates directory if necessary
              if !fs.existsSync assetsDirectory
                fs.mkdirSync assetsDirectory
              #Sets full img path
              fullname = join(assetsDirectory, filename)

          # Text is what will be printed into the new line. So basically the link to the new file
          text = ""
          # This should only happen, if we are in the last line of file and insert an image there
          if editor.getCursorScreenPosition().row == editor.getLastScreenRow()
             text += "\r\n"
          # Imagelink for markdown files
          if(fileFormat == "md")
            text += '![' + words + ']('
            text += join(subFolderToUse, filename) + ') '
          # Imagelink for rst files. will also have an alt text
          else if (fileFormat == "rst")
            text += ".. figure:: "
            text += join(subFolderToUse, filename) + '\r\n'
            text += "\t:alt: " + words + "\n\n"
            text += "\t" + words
          # We need this emmptyline so that the following line is separated
          text += "\r\n"
          #Creates the actual image on the fileSystem
          fs.writeFileSync fullname, img.toPng()
          # Writes the actual link into the editor
          paste_text cursor, text
        # only prints out an error on the console and restores the original text in the line
        catch error
          console.log("Error" + error)
          paste_text cursor, "\r\n" + words + "\r\n"


#Not in use right now
# deletes the file in the given path
delete_file = (file_path) ->
    fs.unlink file_path, (err) ->
        if err
            console.log 'Deleted'+ fullname



#Makes the first letter of the word big
makeBig = (word) ->

# Pastes the link into the file
paste_text = (cursor, text) ->
    cursor.insertText text
    position = cursor.getCursorBufferPosition()
    position.row = position.row - 1
    position.column = position.column + text.length + 1
    cursor.setCursorBufferPosition position

# Reacting to changes in the settings
