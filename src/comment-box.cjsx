React = require 'react'
ToggleChildren = require './mixins/toggle-children'
Validations  = require './mixins/validations'
Feedback = require './mixins/feedback'
CommentPreview = require './comment-preview'
CommentHelp = require './comment-help'
CommentImageSelector = require './comment-image-selector'
m = require './lib/markdown-insert'

module?.exports = React.createClass
  displayName: 'Commentbox'
  mixins: [ToggleChildren, Validations, Feedback]

  validations: [
    {
      check: (text) -> text.trim().length is 0
      error: "Comments must have content"
    }
  ]

  propTypes:
    submit: React.PropTypes.string
    header: React.PropTypes.string
    placeholder: React.PropTypes.string
    submitFeedback: React.PropTypes.string
    onSubmitComment: React.PropTypes.func # called on submit and passed (e, textarea-content, focusImage)
    parentValidationErrors: React.PropTypes.func # runs on submit, should return a bool if should continue to run onSubmitComment

  getDefaultProps: ->
    submit: "Submit"
    header: "Add to the discussion"
    placeholder: "Type your comment here"
    submitFeedback: "Comment Successfully Submitted"
    content: null
    focusImage: null

  getInitialState: ->
    focusImage: @props.focusImage
    content: @props.content

  onSubmitComment: (e) ->
    e.preventDefault()
    textareaValue = @refs.textarea.getDOMNode().value
    return if @setValidationErrors(textareaValue) or @props.parentValidationErrors?()

    @props.onSubmitComment?(e, textareaValue, @state.focusImage)
    # optional function called on submit ^
    # TODO: update this submit stuff for better reuse / prod

    @refs.textarea.getDOMNode().value = ""
    @hideChildren()
    @setState content: ""
    @setFeedback @props.submitFeedback

  onPreviewClick: (e) ->
    @toggleComponent('preview')

  onHelpClick: (e) ->
    @toggleComponent('help')

  onImageSelectClick: (e) ->
    @toggleComponent('image-selector')

  onInsertLinkClick: (e) ->
    @wrapSelectionIn(m.hrefLink)

  onInsertImageClick: (e) ->
    @wrapSelectionIn(m.imageLink)

  onBoldClick: (e) ->
    @wrapSelectionIn(m.bold)

  onItalicClick: (e) ->
    @wrapSelectionIn(m.italic)

  onHeadingClick: (e) ->
    @wrapSelectionIn(m.heading, ensureNewLine: true)

  onQuoteClick: ->
    @wrapSelectionIn(m.quote, ensureNewLine: true)

  onHorizontalRuleClick: (e) ->
    @wrapSelectionIn(m.horizontalRule, ensureNewLine: true)

  onStrikethroughClick: (e) ->
    @wrapSelectionIn(m.strikethrough)

  onBulletClick: (e) ->
    @wrapLinesIn(m.bullet, ensureNewLine: true)

  onNumberClick: (e) ->
    @wrapLinesIn(m.numberedList, ensureNewLine: true, incrementLines: true)

  onSelectImage: (image) ->
    @setState focusImage: image.location

  onClearImageClick: (e) ->
    @setState focusImage: null

  onInputChange: ->
    @setState content: @refs.textarea.getDOMNode().value

  render: ->
    validationErrors = @renderValidations()
    feedback = @renderFeedback()

    <div className="talk-comment-box">
      <h1>{@props.header}</h1>

      {if @state.focusImage
        <img className="talk-comment-focus-image" src={@state.focusImage} />}

      {feedback}

      <div className="talk-comment-buttons-container">
        <button className='talk-comment-insert-link-button' onClick={@onInsertLinkClick}>Insert Link</button>
        <button className='talk-comment-insert-image-button' onClick={@onInsertImageClick}>Insert Image</button>
        <button className='talk-comment-bold-button' onClick={@onBoldClick}>Bold</button>
        <button className='talk-comment-italic-button' onClick={@onItalicClick}>Italicize</button>
        <button className='talk-comment-insert-quote-button' onClick={@onQuoteClick}>Quote</button>
        <button className='talk-comment-heading-button' onClick={@onHeadingClick}>Heading</button>
        <button className='talk-comment-hr-button' onClick={@onHorizontalRuleClick}>Insert Line</button>
        <button className='talk-comment-strikethrough-button' onClick={@onStrikethroughClick}>Strikethrough</button>
        <button className='talk-comment-bullet-button' onClick={@onBulletClick}>Bullet</button>
        <button className='talk-comment-number-button' onClick={@onNumberClick}>Number</button>
      </div>

      <form className="talk-comment-form" onSubmit={@onSubmitComment}>
        <textarea value={@state.content} onChange={@onInputChange} ref="textarea" placeholder={@props.placeholder} />
        <section>
          <button
            type="button"
            className="talk-comment-image-select-button #{if @state.showing is 'image-selector' then 'active' else ''}"
            onClick={@onImageSelectClick}>
            Featured Image
          </button>

          <button
            type="button"
            className="talk-comment-preview-button #{if @state.showing is 'preview' then 'active' else ''}"
            onClick={@onPreviewClick}>
            Preview
          </button>

          <button type="button"
            className="talk-comment-help-button #{if @state.showing is 'help' then 'active' else ''}"
            onClick={@onHelpClick}>
            Help
          </button>

          <button type="submit" className='talk-comment-submit-button'>{@props.submit}</button>
        </section>
        {validationErrors}
      </form>

      <div className="talk-comment-children">
        {switch @state.showing
          when 'image-selector'
            <CommentImageSelector
              onSelectImage={@onSelectImage}
              onClearImageClick= {@onClearImageClick}/>
          when 'preview'
            <CommentPreview content={@state.content} />
          when 'help'
            <CommentHelp />}
      </div>
    </div>

  wrapSelectionIn: (wrapFn, opts = {}) ->
    # helper to call markdown-insert functions on the textarea
    # wrapFn takes / returns a string (from ./lib/markdown-insert.cjsx)

    textarea = @refs.textarea.getDOMNode()
    selection = m.getSelection(textarea)
    {text, cursor} = wrapFn(selection)

    m.insertAtCursor(text, textarea, cursor, opts)
    @onInputChange()

  wrapLinesIn: (wrapFn, opts = {}) ->
    textarea = @refs.textarea.getDOMNode()
    lines = m.getSelection(textarea).split("\n")

    formattedText = lines
      .map (line) -> wrapFn(line).text
      .join("\n")

    # increment the line numbers in a list, if that option is specified
    if opts.incrementLines and opts.ensureNewLine
      begInputValue = textarea.value.substring(0, textarea.selectionStart) + "\n"
      formattedText = m.incrementedListItems(begInputValue, formattedText)

    cursor = {start: formattedText.length, end: formattedText.length}

    m.insertAtCursor(formattedText, textarea, cursor, opts)
    @onInputChange()
