import { useEffect, useState } from 'react'
import loginService from "./services/login"
import noteService from './services/notes'
import LoginForm from './components/LoginForm'
import Note from './components/Note'
import Notification from './components/Notification'
import Footer from './components/Footer'
import NoteForm from './components/NoteForm'

const App = () => {
  const [notes, setNotes] = useState([])
  const [newNote, setNewNote] = useState("")
  const [showAll, setShowAll] = useState(true)
  const [errorMessage, setErrorMessage] = useState(null)
  const [username, setUsername] = useState("")
  const [password, setPassword] = useState("")
  const [user, setUser] = useState(null)

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

  const login = async (event) => {
    event.preventDefault()

    try {
      const user = await loginService.login({ username, password })
      noteService.setToken(user.token)
      window.localStorage.setItem("loggedNoteappUser", JSON.stringify(user))
      setUser(user)
      setUsername("")
      setPassword("")
    } catch (exception) {
      setErrorMessage("Wrong Credentials")
      setTimeout(() => {
        setErrorMessage(null)
      }, 5000)
    }
  }

  const addNote = (event) => {
    event.preventDefault()
    const noteObject = {
      content: newNote,
      important: Math.random() < 0.5
    }
    noteService
      .create(noteObject)
      .then(returnedNote => {
        setNotes(notes.concat(returnedNote))
        setNewNote("")
      })
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
          <LoginForm
            username={username}
            handleUsernameChange={({ target }) => setUsername(target.value)}
            password={password}
            handlePasswordChange={({ target }) => setPassword(target.value)}
            handleLogin={login} /> :
          <div>
            <p>{user.name} logged-in</p>
            <NoteForm
              newNote={newNote}
              handleNoteChange={({ target }) => setNewNote(target.value)}
              addNote={addNote}
            />
          </div>
      }
      <div>
        <button onClick={() => setShowAll(!showAll)}>
          show {showAll ? "important" : "all"}
        </button>
      </div>
      <ul>
        {notesToShow.map(note => <Note key={note.id} note={note} toggleImportance={() => toggleImportance(note)} />)}
      </ul>
      <Footer />
    </div>
  )
}

export default App
