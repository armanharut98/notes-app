import { forwardRef, useImperativeHandle, useState } from "react"
import PropTypes from "prop-types"

const Togglable = forwardRef((props, ref) => {
    const [visible, setVisible] = useState(false)

    const showWhenVisible = { display: visible ? "" : "none" }
    const hideWhenVisible = { display: visible ? "none" : "" }

    const toggleVisibility = () => {
        setVisible(!visible)
    }

    useImperativeHandle(ref, () => {
        return {
            toggleVisibility
        }
    })

    return (
        <div>
            <div style={hideWhenVisible}>
                <button onClick={() => setVisible(true)}>{props.buttonLabel}</button>
            </div>
            <div style={showWhenVisible} className="togglableContent">
                {props.children}
                <button onClick={() => setVisible(false)}>cancel</button>
            </div>
        </div>
    )
})

Togglable.displayName = "Togglable"

Togglable.propTypes = {
    buttonLabel: PropTypes.string.isRequired
}

export default Togglable
