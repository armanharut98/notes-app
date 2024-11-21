import { useState } from "react"
import PropTypes from "prop-types"

const NoteForm = ({ createNote }) => {
    const [newNote, setNewNote] = useState("")

    const addNote = (event) => {
        event.preventDefault()
        createNote({
            content: newNote,
            important: true
        })
        setNewNote("")
    }

    return (
        <>
            <h2>Create a new note</h2>
            <form onSubmit={addNote}>
                <input
                    id="new-note"
                    value={newNote}
                    onChange={({ target }) => setNewNote(target.value)}
                />
                <button type='submit'>save</button>
            </form>
        </>
    )
}

NoteForm.propTypes = {
    createNote: PropTypes.func.isRequired
}

export default NoteForm