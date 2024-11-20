import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import NoteForm from "./NoteForm"

describe("<NoteForm />", () => {
    test("updates parent state and calls onSubmit", async () => {
        const createNoteMock = vi.fn()
        const user = userEvent.setup()

        render(<NoteForm createNote={createNoteMock} />)

        const input = screen.getByRole("textbox")
        const sendButton = screen.getByText("save")

        await user.type(input, "testing a form...")
        await user.click(sendButton)

        expect(createNoteMock.mock.calls).toHaveLength(1)
        expect(createNoteMock.mock.calls[0][0].content).toBe("testing a form...")
    })
})
