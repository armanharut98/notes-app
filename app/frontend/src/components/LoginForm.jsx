const LoginForm = ({ username, handleUsernameChange, password, handlePasswordChange, handleLogin }) => {
    return (
        <form onSubmit={handleLogin}>
            <div>
                username: <input value={username} onChange={handleUsernameChange} />
            </div>
            <div>
                password: <input value={password} onChange={handlePasswordChange} />
            </div>
            <button type="submit">login</button>
        </form>
    )
}

export default LoginForm
