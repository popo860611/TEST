import tkinter as tk
from tkinter import ttk, messagebox
from dataclasses import asdict
from typing import Callable

from .booking.bot import BookingInfo


class BookingGUI:
    def __init__(self, on_submit: Callable[[BookingInfo], None]):
        self.on_submit = on_submit
        self.root = tk.Tk()
        self.root.title('Inline Booking Bot')
        self._build()

    def _build(self) -> None:
        frame = ttk.Frame(self.root, padding=10)
        frame.grid(sticky='nsew')

        ttk.Label(frame, text='Restaurant URL').grid(row=0, column=0, sticky='e')
        self.url = ttk.Entry(frame, width=40)
        self.url.grid(row=0, column=1)

        ttk.Label(frame, text='People').grid(row=1, column=0, sticky='e')
        self.people = ttk.Entry(frame)
        self.people.grid(row=1, column=1)

        ttk.Label(frame, text='Time (HH:MM)').grid(row=2, column=0, sticky='e')
        self.time = ttk.Entry(frame)
        self.time.grid(row=2, column=1)

        ttk.Label(frame, text='Name').grid(row=3, column=0, sticky='e')
        self.name = ttk.Entry(frame)
        self.name.grid(row=3, column=1)

        ttk.Label(frame, text='Gender').grid(row=4, column=0, sticky='e')
        self.gender = ttk.Combobox(frame, values=['male', 'female'])
        self.gender.grid(row=4, column=1)

        ttk.Label(frame, text='Phone').grid(row=5, column=0, sticky='e')
        self.phone = ttk.Entry(frame)
        self.phone.grid(row=5, column=1)

        ttk.Label(frame, text='Email').grid(row=6, column=0, sticky='e')
        self.email = ttk.Entry(frame)
        self.email.grid(row=6, column=1)

        submit = ttk.Button(frame, text='Submit', command=self._submit)
        submit.grid(row=7, column=1, pady=5)

    def _submit(self) -> None:
        try:
            info = BookingInfo(
                url=self.url.get(),
                people=int(self.people.get()),
                time=self.time.get(),
                name=self.name.get(),
                gender=self.gender.get(),
                phone=self.phone.get(),
                email=self.email.get(),
            )
        except Exception as exc:
            messagebox.showerror('Error', str(exc))
            return
        self.on_submit(info)

    def run(self) -> None:
        self.root.mainloop()
