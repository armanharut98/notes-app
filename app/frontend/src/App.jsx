import { useEffect, useState, useRef } from "react"
import loginService from "./services/login"
import noteService from "./services/notes"
import LoginForm from "./components/LoginForm"
import Note from "./components/Note"
import Notification from "./components/Notification"
import Footer from "./components/Footer"
import NoteForm from "./components/NoteForm"
import Togglable from "./components/Togglable"

const App = () => {
    const [notes, setNotes] = useState([])
    const [showAll, setShowAll] = useState(true)
    const [errorMessage, setErrorMessage] = useState(null)
    const [user, setUser] = useState(null)
    const noteFormRef = useRef()

    useEffect(() => {
        noteService
            .getAll()
            .then(initialNotes => {
                setNotes(initialNotes)
            })
    }, [])

    useEffect(() => {
        const loggedUserJSON = window.localStorage.getItem("loggedNoteappUser")
        if (loggedUserJSON) {
            const user = JSON.parse(loggedUserJSON)
            setUser(user)
            noteService.setToken(user.token)
        }
    }, [])

    const login = async (credentials) => {
        try {
            const user = await loginService.login(credentials)
            noteService.setToken(user.token)
            window.localStorage.setItem("loggedNoteappUser", JSON.stringify(user))
            setUser(user)
        } catch (exception) {
            setErrorMessage("Wrong Credentials")
            setTimeout(() => {
                setErrorMessage(null)
            }, 5000)
        }
    }

    const logout = () => {
        setUser(null)
        window.localStorage.removeItem("loggedNoteappUser")
    }

    const addNote = async (noteObject) => {
        try {
            const returnedNote = await noteService.create(noteObject)
            setNotes(notes.concat(returnedNote))
            noteFormRef.current.toggleVisibility()
        } catch (exception) {
            setErrorMessage(`Unable to save the note: ${exception.message}`)
            setTimeout(() => {
                setErrorMessage(null)
            })
        }
    }

    const toggleImportance = (note) => {
        noteService
            .update(note.id, { ...note, important: !note.important })
            .then(updatedNote => {
                setNotes(notes.map(n => {
                    return n.id === note.id
                        ? updatedNote
                        : n
                }))
            })
            .catch(error => {
                console.log(error)
                setErrorMessage(
                    `Note '${note.content}' was already removed from server`
                )
                setTimeout(() => {
                    setErrorMessage(null)
                }, 5000)
                setNotes(notes.filter(n => n.id !== note.id))
            })
    }

    const notesToShow = showAll
        ? notes
        : notes.filter(n => n.important)

    return (
        <div>
            <h1>Notes</h1>
            <Notification message={errorMessage} />
            {
                user === null ?
                    <Togglable buttonLabel="login">
                        <LoginForm login={login} />
                    </Togglable> :
                    <div>
                        <p>
                            {user.name} logged in
                            <button onClick={logout}>logout</button>
                        </p>
                        <Togglable buttonLabel="create" ref={noteFormRef}>
                            <NoteForm createNote={addNote} />
                        </Togglable>
                    </div>
            }
            <div>
                <button onClick={() => setShowAll(!showAll)}>
                    show {showAll ? "important" : "all"}
                </button>
            </div>
            <ul>
                {
                    notesToShow.length > 0
                        ? notesToShow.map(note => <Note key={note.id} note={note} toggleImportance={() => toggleImportance(note)} />)
                        : null
                }
            </ul>
            <Footer />
        </div>
    )
}

export default App
