export default function Home() {
  return (
    <main className="container">
      <h1>Welcome to Next.js Frontend with some changes</h1>
      <p>This application is running on AWS ECS Fargate</p>
      <div className="info">
        <p>Environment: {process.env.NEXT_PUBLIC_ENV || 'development'}</p>
        <p>Deployed via Bitbucket Pipelines</p>
      </div>
    </main>
  )
}

