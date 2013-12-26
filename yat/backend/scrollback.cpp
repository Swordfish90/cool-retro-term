/******************************************************************************
* Copyright (c) 2013 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
******************************************************************************/

#include "scrollback.h"

#include "screen_data.h"
#include "screen.h"
#include "block.h"

#define P_VAR(variable) \
    #variable ":" << variable

Scrollback::Scrollback(size_t max_size, ScreenData *screen_data)
    : m_screen_data(screen_data)
    , m_height(0)
    , m_width(0)
    , m_block_count(0)
    , m_max_size(max_size)
    , m_adjust_visible_pages(0)
{
}

void Scrollback::addBlock(Block *block)
{
    if (!m_max_size) {
        delete block;
        return;
    }

    m_blocks.push_back(block);
    block->releaseTextObjects();
    m_block_count++;
    m_height += m_blocks.back()->lineCount();

    while (m_height - m_blocks.front()->lineCount() >= m_max_size) {
        m_block_count--;
        m_height -= m_blocks.front()->lineCount();
        delete m_blocks.front();
        m_blocks.pop_front();
        m_adjust_visible_pages++;
    }

    m_visible_pages.clear();
}

Block *Scrollback::reclaimBlock()
{
    if (m_blocks.empty())
        return nullptr;

    Block *last = m_blocks.back();
    last->setWidth(m_width);
    m_block_count--;
    m_height -= last->lineCount();
    m_blocks.pop_back();

    m_visible_pages.clear();
    return last;
}

void Scrollback::ensureVisiblePages(int top_line)
{
    if (top_line < 0)
        return;
    if (size_t(top_line) >= m_height)
        return;

    uint height = std::max(m_screen_data->screen()->height(), 1);

    int complete_pages = m_height / height;
    int remainder = m_height - (complete_pages * height);

    int top_page = top_line / height;
    int bottom_page = top_page + 1;

    std::set<int> pages_to_update;
    pages_to_update.insert(top_page);
    if (bottom_page * height < m_height)
        pages_to_update.insert(bottom_page);

    for (auto it = m_visible_pages.begin(); it != m_visible_pages.end(); ++it) {
        Page &page = *it;
        if (pages_to_update.count(page.page_no) != 0) {
            if (page.page_no < complete_pages) {
                ensurePageVisible(page, height);
            } else if (page.page_no == complete_pages) {
                ensurePageVisible(page, remainder);
            }
            pages_to_update.erase(page.page_no);
        } else {
            ensurePageNotVisible(page);
            auto to_remove = it;
            --it;
            m_visible_pages.erase(to_remove);
        }
    }

    for (auto it = pages_to_update.begin(); it != pages_to_update.end(); ++it) {
        auto page_it = findIteratorForPage(*it);
        m_visible_pages.push_back( { *it, 0, page_it } );
        if (*it < complete_pages) {
            ensurePageVisible(m_visible_pages.back(), height);
        } else if (*it == complete_pages) {
            ensurePageVisible(m_visible_pages.back(), remainder);
        }
    }
}

void Scrollback::ensurePageVisible(Page &page, int new_height)
{
    if (page.size == new_height || !m_block_count)
        return;

    int line_no = page.page_no * m_screen_data->screen()->height();
    auto it = page.it;
    std::advance(it, page.size);
    for (int i = page.size; i < new_height; ++it, i++) {
        (*it)->setLine(line_no + i);
        (*it)->dispatchEvents();
    }
    page.size = new_height;
}

void Scrollback::ensurePageNotVisible(Page &page)
{
    auto it = page.it;
    for (int i = 0; i < page.size; ++it, i++) {
        (*it)->releaseTextObjects();
    }
    page.size = 0;
}

std::list<Block *>::iterator Scrollback::findIteratorForPage(int page_no)
{
    uint line = page_no * m_screen_data->screen()->height();
    Q_ASSERT(line < m_height);
    for (auto it = m_visible_pages.begin(); it != m_visible_pages.end(); ++it) {
        Page &page = *it;
        int diff = page_no - page.page_no;
        if (diff < 5 && diff > 5) {
            auto to_return = page.it;
            int advance = diff * m_screen_data->screen()->height();
            std::advance(to_return, advance);
            return to_return;
        }
    }

    if (line > m_height / 2) {
        auto to_return = m_blocks.end();
        std::advance(to_return, line - m_height);
        return to_return;
    }

    auto to_return = m_blocks.begin();
    std::advance(to_return, line);
    return to_return;
}

void Scrollback::adjustVisiblePages()
{
    if (!m_adjust_visible_pages)
        return;

    for (auto it = m_visible_pages.begin(); it != m_visible_pages.end(); ++it) {
        Page &page = *it;
        const size_t line_for_page = page.page_no * m_screen_data->screen()->height();
        if (line_for_page < m_adjust_visible_pages) {
            auto to_remove = it;
            --it;
            m_visible_pages.erase(to_remove);
        } else {
            page.size = 0;
            std::advance(page.it, m_adjust_visible_pages);
        }
    }

    m_adjust_visible_pages = 0;
}

size_t Scrollback::height() const
{
    return m_height;
}

void Scrollback::setWidth(int width)
{
    m_width = width;
}

QString Scrollback::selection(const QPoint &start, const QPoint &end) const
{
    Q_UNUSED(start);
    Q_UNUSED(end);
    return QString();
}
