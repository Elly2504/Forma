"use client";

import Link from "next/link";

export default function DashboardPage() {
    return (
        <main className="min-h-screen p-6">
            {/* Header */}
            <header className="flex items-center justify-between mb-8">
                <Link href="/dashboard" className="flex items-center gap-2">
                    <span className="text-2xl">⚽</span>
                    <span className="text-xl font-bold text-gradient">KitTicker</span>
                </Link>
                <div className="flex items-center gap-4">
                    <div className="text-sm text-[var(--text-secondary)]">
                        <span className="text-[var(--gold-500)] font-semibold">3</span> valuations left
                    </div>
                    <Link href="/pricing" className="btn-secondary text-sm py-2 px-4">
                        Upgrade
                    </Link>
                    {/* User Menu */}
                    <div className="relative group">
                        <button className="w-9 h-9 rounded-full bg-[var(--gold-500)] text-black font-bold flex items-center justify-center">
                            U
                        </button>
                        <div className="absolute right-0 top-full mt-2 w-48 glass-card p-2 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all">
                            <div className="px-3 py-2 border-b border-[var(--border-subtle)]">
                                <p className="text-sm font-medium">user@example.com</p>
                                <p className="text-xs text-[var(--text-muted)]">Free Plan</p>
                            </div>
                            <Link
                                href="/dashboard/settings"
                                className="block px-3 py-2 text-sm text-[var(--text-secondary)] hover:text-white hover:bg-[var(--bg-elevated)] rounded transition-colors"
                            >
                                Settings
                            </Link>
                            <button
                                className="w-full text-left px-3 py-2 text-sm text-red-400 hover:bg-[var(--bg-elevated)] rounded transition-colors"
                                onClick={() => {
                                    // TODO: Supabase signout
                                    window.location.href = "/login";
                                }}
                            >
                                Sign Out
                            </button>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <div className="max-w-4xl mx-auto">
                <h1 className="text-3xl font-bold mb-2">Your Dashboard</h1>
                <p className="text-[var(--text-secondary)] mb-8">
                    Start valuing your vintage football shirt collection
                </p>

                {/* New Valuation Card */}
                <Link href="/dashboard/valuation/new" className="block">
                    <div className="glass-card-gold p-8 text-center hover:border-[var(--gold-500)] transition-colors cursor-pointer gold-glow">
                        <div className="text-5xl mb-4">📸</div>
                        <h2 className="text-xl font-semibold mb-2">New Valuation</h2>
                        <p className="text-[var(--text-secondary)] mb-4">
                            Upload 4 photos and get an AI-powered condition grade and price estimate
                        </p>
                        <span className="btn-primary">
                            Start Valuation
                        </span>
                    </div>
                </Link>

                {/* Recent Valuations */}
                <div className="mt-12">
                    <h2 className="text-xl font-semibold mb-4">Recent Valuations</h2>
                    <div className="glass-card p-8 text-center">
                        <p className="text-[var(--text-muted)]">
                            No valuations yet. Start your first one above!
                        </p>
                    </div>
                </div>

                {/* Quick Stats */}
                <div className="mt-12 grid sm:grid-cols-3 gap-4">
                    <div className="glass-card p-6 text-center">
                        <p className="text-3xl font-bold text-gradient">0</p>
                        <p className="text-sm text-[var(--text-muted)]">Total Valuations</p>
                    </div>
                    <div className="glass-card p-6 text-center">
                        <p className="text-3xl font-bold text-gradient">3</p>
                        <p className="text-sm text-[var(--text-muted)]">Credits Left</p>
                    </div>
                    <div className="glass-card p-6 text-center">
                        <p className="text-3xl font-bold text-[var(--text-secondary)]">-</p>
                        <p className="text-sm text-[var(--text-muted)]">Collection Value</p>
                    </div>
                </div>
            </div>
        </main>
    );
}
