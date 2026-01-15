import Link from "next/link";

export default function HomePage() {
  return (
    <main className="min-h-screen flex items-center justify-center p-4">
      <div className="text-center max-w-2xl">
        <div className="flex items-center justify-center gap-2 mb-6">
          <span className="text-4xl">⚽</span>
          <span className="text-3xl font-bold text-gradient">KitTicker</span>
        </div>

        <h1 className="text-4xl md:text-5xl font-bold mb-4">
          Know Your Shirt&apos;s <span className="text-gradient">True Value</span>
        </h1>

        <p className="text-xl text-[var(--text-secondary)] mb-8">
          AI-powered vintage football shirt valuation in 60 seconds
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link href="/signup" className="btn-primary text-lg px-8 py-4">
            Try Free — No Credit Card
          </Link>
          <Link href="/login" className="btn-secondary text-lg px-8 py-4">
            Sign In
          </Link>
        </div>

        <p className="mt-4 text-sm text-[var(--text-muted)]">
          3 free valuations/month
        </p>
      </div>
    </main>
  );
}
