import { Suspense, useState } from "react"
import reactLogo from "./assets/react.svg"
import viteLogo from "/vite.svg"
import "./App.css"
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>

      <Items />
    </>
  )
}

function Items() {
  // Mutations //isPending not used currently, left for learning.
  const { mutate: createPost, isPending: isDeleting } = useMutation({
    mutationFn: async () => {
      const res = await fetch("http://localhost:3069/test/post", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: "1" }),
      })
      return res
    },
    onSuccess: () => {
      // Invalidate and refetch
      console.log("succes")
    },
    onError: (e: any) => {
      console.log("error ", e)
    },
  })

  const { mutate: createPut } = useMutation({
    mutationFn: async () => {
      const res = await fetch("http://localhost:3069/test/put", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: "1" }),
      })
      return res
    },
    onSuccess: () => {
      // Invalidate and refetch
      console.log("success")
    },
    onError: (e: any) => {
      console.log("error ", e)
    },
  })

  const { mutate: createDelete } = useMutation({
    mutationFn: async () => {
      const res = await fetch("http://localhost:3069/test/delete", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: "1" }),
      })
      return res
    },
    onSuccess: () => {
      // Invalidate and refetch
      console.log("success")
    },
    onError: (e: any) => {
      console.log("error ", e)
    },
  })

  const { mutate: createGet } = useMutation({
    mutationFn: async () => {
      const res = await fetch("http://localhost:3069/test/get", {
        method: "GET",
        headers: { "Content-Type": "application/json" },
      })
      return res
    },
    onSuccess: () => {
      // Invalidate and refetch
      console.log("success")
    },
    onError: (e: any) => {
      console.log("error ", e)
    },
  })

  const { mutate: createPatch } = useMutation({
    mutationFn: async () => {
      const res = await fetch("http://localhost:3069/test/patch", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: "1" }),
      })
      return res
    },
    onSuccess: () => {
      // Invalidate and refetch
      console.log("success")
    },
    onError: (e: any) => {
      console.log("error ", e)
    },
  })

  return (
    <div>
      <button
        onClick={() => {
          createGet()
        }}
      >
        GET
      </button>
      <button
        onClick={() => {
          createPost()
        }}
      >
        Post
      </button>
      <button
        onClick={() => {
          createPut()
        }}
      >
        Put
      </button>
      <button
        onClick={() => {
          createDelete()
        }}
      >
        Delete
      </button>
      <button
        onClick={() => {
          createPatch()
        }}
      >
        Patch
      </button>
    </div>
  )
}

export default App
